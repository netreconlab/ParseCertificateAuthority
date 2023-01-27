//
//  CertificateAuthorityServer.swift
//  Assuage
//
//  Created by Esther Max-Onakpoya on 8/19/22.
//  Copyright © 2022 NetReconLab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import ParseSwift

// MARK: Configure Framework
public func initialize(configuration: ParseCertificateAuthorityConfiguration) {
    ParseCA.configuration = configuration
}

/// The current `ParseCertificateAuthorityConfiguration` for `ParseCertificateAuthority`.
public var configuration: ParseCertificateAuthorityConfiguration {
    ParseCA.configuration
}

// MARK: Public Methods

/**
 Determine if an object has a root CA certificate.
 - parameter object: The `ParseCertificatable` conforming object to check.
 - returns: **true** if the object has the certificate, **false** otherwise.
 */
public func hasRootCertificate<T: ParseCertificatable>(_ object: T?) -> Bool {
    object?.rootCertificate != nil
}

/**
 Determine if an object has a certificate.
 - parameter object: The `ParseCertificatable` conforming object to check.
 - returns: **true** if the object has the certificate, **false** otherwise.
 */
public func hasCertificate<T: ParseCertificatable>(_ object: T?) -> Bool {
    object?.certificate != nil
}

/**
 Requests new certificates without checking to see if an object already has them.
 - parameter user: The `ParseUser` conforming user to create the certificate for.
 - parameter object: The `ParseCertificatable` conforming object to check.
 - returns: **true** if the object has the certificate, **false** otherwise.
 - note: This is useful for when certificates have expired.
 */
public func requestNewCertificates<T, U>(_ user: T?,
                                         // swiftlint:disable:next line_length
                                         object: U?) async throws -> (String?, String?) where T: ParseUser, U: ParseCertificatable {

    guard let userObjectId = user?.objectId,
          let certificateId = object?.certificateId,
          let csr = object?.csr else {
        throw ParseError(code: .otherCause,
                         // swiftlint:disable:next line_length
                         message: "Missing user objectId, certificateId, or csr. User:\(String(describing: user)); Object: \(String(describing: object))")
    }

    try await verifyAndCreateUserOnCA(userUUID: userObjectId)

    let body = CAServerBody(user: userObjectId,
                            certificateId: certificateId,
                            csr: csr)
    let certificate = try await restfullCertificates(httpMethod: .POST,
                                                     body: body,
                                                     certificateType: .user).removingPercentEncoding

    do {
        let rootCertificate = try await restfullCertificates(httpMethod: .GET, certificateType: .root)
        return (certificate, rootCertificate.removingPercentEncoding)
    } catch {
        return (certificate, nil)
    }

}

/// Get/create new cert when necessary. Will not create the new cert if it's already in Installation.
public func getCertificates<T, U>(_ user: T?,
                                  // swiftlint:disable:next line_length
                                  object: U?) async throws -> (String?, String?) where T: ParseUser, U: ParseCertificatable {

    guard let userObjectId = user?.objectId,
          let certificateId = object?.certificateId,
          let csr = object?.csr else {
        throw ParseError(code: .otherCause,
                         // swiftlint:disable:next line_length
                         message: "Missing user objectId, certificateId, or csr. User:\(String(describing: user)); Installation: \(String(describing: object))")
    }

    if hasCertificate(object) && hasRootCertificate(object) {
        throw ParseError(code: .duplicateRequest, message: "Installation already has certificates")
    }

    try await verifyAndCreateUserOnCA(userUUID: userObjectId, createAccountIfNeeded: true)
    var certificate: String?
    if !hasCertificate(object) {
        do {
            certificate = try await restfullCertificates(httpMethod: .GET,
                                                         certificateType: .user,
                                                         certificateId: certificateId)
        } catch {
            let body = CAServerBody(user: userObjectId,
                                    certificateId: certificateId,
                                    csr: csr)
            certificate = try await restfullCertificates(httpMethod: .POST,
                                                         body: body,
                                                         certificateType: .user)
        }
        certificate = certificate?.removingPercentEncoding
    }

    do {
        let rootCertificate = try await restfullCertificates(httpMethod: .GET, certificateType: .root)
        return (certificate, rootCertificate.removingPercentEncoding)
    } catch {
        return (certificate, nil)
    }

}

// MARK: Internal

internal struct ParseCA {
    static var configuration: ParseCertificateAuthorityConfiguration!
}

func restfullCertificates(httpMethod: RestMethod,
                          body: CAServerBody? = nil,
                          certificateType: CertificateType,
                          certificateId: String? = nil) async throws -> String {

    if certificateType == .root && httpMethod != .GET {
        throw ParseError(code: .otherCause,
                         message: "Can only GET Root certificate from CA.")
    }

    let url: URL!
    if certificateType == .root {
        url = ParseCA.configuration.caRootCertificateURL
    } else if let certificateId = certificateId {
        url = ParseCA.configuration.caCertificatesURL.appendingPathComponent(certificateId)
    } else {
        url = ParseCA.configuration.caCertificatesURL
    }

    let request = try prepareRequest(url, method: httpMethod, body: body)

    let (data, response) = try await URLSession.shared.dataTask(for: request)
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw ParseError(code: .otherCause,
                         message: "Response from CA: \(response)")
    }
    guard let result = try? JSONDecoder().decode(CAServerResponse.self, from: data) else {
        return try JSONDecoder().decode(String.self, from: data)
    }
    return result.certificate

}

func verifyAndCreateUserOnCA(userUUID: String,
                             createAccountIfNeeded: Bool = true) async throws {

    do {
        try await restfullAppUsers(httpMethod: .GET, objectId: userUUID)
    } catch {
        guard createAccountIfNeeded else {
            throw error
        }
        let body = CAServerBody(user: userUUID)
        try await restfullAppUsers(httpMethod: .POST,
                                   body: body,
                                   objectId: nil)
    }

}

func restfullAppUsers(httpMethod: RestMethod,
                      body: CAServerBody? = nil,
                      objectId: String?) async throws {

    let url: URL!
    if let objectId = objectId {
        url = ParseCA.configuration.caUsersPathURL.appendingPathComponent(objectId)
    } else {
        url = ParseCA.configuration.caUsersPathURL
    }

    let request = try prepareRequest(url, method: httpMethod, body: body)

    let (_, response) = try await URLSession.shared.dataTask(for: request)
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw ParseError(code: .otherCause,
                         message: "Response from CA: \(response)")
    }

}

func prepareRequest<V: Encodable>(_ url: URL,
                                  method: RestMethod,
                                  body: V?) throws -> URLRequest {

    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    if let body = body {
        request.httpBody = try JSONEncoder().encode(body)
    }
    request.addValue("Basic base64", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    return request

}
