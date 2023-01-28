//
//  ParseCertificatable.swift
//  
//
//  Created by Corey Baker on 1/27/23.
//

import Foundation
import ParseSwift

/**
 Objects that conform to the `ParseCertificatable` protocol are
 `ParseObject`'s that have special properties and methods to support
 certificates and communicating with a
 [ca-server](https://github.com/netreconlab/ca-server).
 */
public protocol ParseCertificatable: ParseObject, Certificatable { }

public extension ParseCertificatable {

    /**
     Requests new certificates without checking to see if an object already has them.
     - parameter user: The `ParseUser` conforming user to create the certificate for.
     - parameter object: The `ParseCertificatable` conforming object to check.
     - returns: A tuple where the first item is the user certificate and the second item is the root certificate.
     - throws: An error of `ParseError` type.
     - note: This is useful for when certificates have expired.
     */
    func requestNewCertificates<T>(_ user: T?) async throws -> (String?, String?) where T: ParseUser {

        guard let userObjectId = user?.objectId,
              let certificateId = self.certificateId,
              let csr = self.csr else {
            throw ParseError(code: .otherCause,
                             // swiftlint:disable:next line_length
                             message: "Missing user objectId, certificateId, or csr. User:\(String(describing: user)); Object: \(self)")
        }

        try await verifyAndCreateUserOnCA(userId: userObjectId)

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

    /**
     Get/create certificates if an object is missing them.
     - parameter user: The `ParseUser` conforming user to create the certificate for.
     - parameter object: The `ParseCertificatable` conforming object to check.
     - returns: A tuple where the first item is the user certificate and the second item is the root certificate.
     - throws: An error of `ParseError` type.
     - note: This is useful when certificates need to be created for the first time. If an object
     already has both certificates, it will simply return the current certificates.
     */
    func getCertificates<T>(_ user: T?) async throws -> (String?, String?) where T: ParseUser {

        guard let userObjectId = user?.objectId,
              let certificateId = self.certificateId,
              let csr = self.csr else {
            throw ParseError(code: .otherCause,
                             // swiftlint:disable:next line_length
                             message: "Missing user objectId, certificateId, or csr. User:\(String(describing: user)); Object: \(self)")
        }

        if hasCertificate(self) && hasRootCertificate(self) {
            throw ParseError(code: .duplicateRequest, message: "Object already has certificates")
        }

        try await verifyAndCreateUserOnCA(userId: userObjectId, createAccountIfNeeded: true)
        var certificate: String?
        if !hasCertificate(self) {
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

}
