//
//  Certificatable.swift
//  
//
//  Created by Corey Baker on 1/28/23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import ParseSwift

/**
 Objects that conform to the `Certificatable` protocol have special properties
 and methods to support certificates and communicating with a
 [ca-server](https://github.com/netreconlab/ca-server).
 */
public protocol Certificatable: Hashable {
    /// The root certificate that signed the `csr` and turned it into a `certificate`.
    var rootCertificate: String? { get set }

    /// The certifcate made from the `csr`.
    var certificate: String? { get set }

    /// The CSR used to make the `certifcate`
    var csr: String? { get set }

    /// The unique identifier for the certificate
    var certificateId: String? { get }
}

// MARK: Public
public extension Certificatable {

    /**
     Determine if an object has a root CA certificate.
     - parameter object: The `Certificatable` conforming object to check.
     - returns: **true** if the object has the certificate, **false** otherwise.
     */
    func hasRootCertificate<T: Certificatable>(_ object: T?) -> Bool {
        object?.rootCertificate != nil
    }

    /**
     Determine if an object has a certificate.
     - parameter object: The `Certificatable` conforming object to check.
     - returns: **true** if the object has the certificate, **false** otherwise.
     */
    func hasCertificate<T: Certificatable>(_ object: T?) -> Bool {
        object?.certificate != nil
    }

    /**
     Requests new certificates without checking to see if an object already has them.
     - parameter userId: The unique user id to create the certificate for.
     - returns: A tuple where the first item is the user certificate and the second item is the root certificate.
     - throws: An error of `ParseError` type.
     - note: This is useful for when certificates have expired.
     */
    func requestNewCertificates(_ userId: String?) async throws -> (String?, String?) {

        guard let userId = userId,
              let certificateId = self.certificateId,
              let csr = self.csr else {
            throw ParseError(code: .otherCause,
                             // swiftlint:disable:next line_length
                             message: "Missing user id, certificateId, or csr. User: \(String(describing: userId)); Object: \(self)")
        }

        try await verifyAndCreateUserOnCA(userId: userId)

        let body = CAServerBody(user: userId,
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

    /**
     Get/create certificates if an object is missing them.
     - parameter userId: The unique user id to create the certificate for.
     - returns: A tuple where the first item is the user certificate and the second item is the root certificate.
     - throws: An error of `ParseError` type.
     - note: This is useful when certificates need to be created for the first time. If an object
     already has both certificates, it will simply return the current certificates.
     */
    func getCertificates(_ userId: String?) async throws -> (String?, String?) {

        guard let userId = userId,
              let certificateId = self.certificateId,
              let csr = self.csr else {
            throw ParseError(code: .otherCause,
                             // swiftlint:disable:next line_length
                             message: "Missing user id, certificateId, or csr. User:\(String(describing: userId)); Object: \(self)")
        }

        if hasCertificate(self) && hasRootCertificate(self) {
            throw ParseError(code: .duplicateRequest, message: "Object already has certificates")
        }

        try await verifyAndCreateUserOnCA(userId: userId, createAccountIfNeeded: true)
        var certificate: String?
        if !hasCertificate(self) {
            do {
                certificate = try await restfullCertificates(httpMethod: .GET,
                                                             certificateType: .user,
                                                             certificateId: certificateId)
            } catch {
                let body = CAServerBody(user: userId,
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

}

// MARK: Internal
extension Certificatable {

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

    func verifyAndCreateUserOnCA(userId: String,
                                 createAccountIfNeeded: Bool = true) async throws {

        do {
            try await restfullAppUsers(httpMethod: .GET, userId: userId)
        } catch {
            guard createAccountIfNeeded else {
                throw error
            }
            let body = CAServerBody(user: userId)
            try await restfullAppUsers(httpMethod: .POST,
                                       body: body,
                                       userId: nil)
        }

    }

    func restfullAppUsers(httpMethod: RestMethod,
                          body: CAServerBody? = nil,
                          userId: String?) async throws {

        let url: URL!
        if let userId = userId {
            url = ParseCA.configuration.caUsersPathURL.appendingPathComponent(userId)
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

}
