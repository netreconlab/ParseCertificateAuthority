//
//  ParseCertificateAuthorityConfiguration.swift
//  
//
//  Created by Corey Baker on 1/27/23.
//

import Foundation
import ParseSwift

/// The configuration for `ParseCertificateAuthority`.
public struct ParseCertificateAuthorityConfiguration: Hashable, Sendable {

    /// The full URL of the **ca-server** to access the root certificate.
    public internal(set) var caRootCertificateURL: URL
    /// The full URL of the **ca-server** to access user certificates.
    public internal(set) var caCertificatesURL: URL
    /// The full URL of the **ca-server** to access users.
    public internal(set) var caUsersPathURL: URL

    /**
     Creat an instance of the configuration.
     - parameter caURLString: The full URL string of the **ca-server**.
     - parameter caRootCertificatePath: The **ca-server** path to access the root certificate.
     - parameter caCertificatesPath: The **ca-server** path to access user certificates.
     - parameter caUsersPath: The **ca-server** path to access users.
     - throws: An error of `ParseError` type.
     */
    public init(
		caURLString: String,
		caRootCertificatePath: String = "/ca_certificate",
		caCertificatesPath: String = "/certificates/",
		caUsersPath: String = "/appusers/"
	) throws {
        guard let caRootCertificateURL = URL(string: caURLString + caRootCertificatePath) else {
            throw ParseError(code: .otherCause,
                             message: "Could not create a url for \(caURLString + caRootCertificatePath)")
        }
        guard let caCertificatesURL = URL(string: caURLString + caCertificatesPath) else {
            throw ParseError(code: .otherCause,
                             message: "Could not create a url for \(caURLString + caCertificatesPath)")
        }
        guard let caUsersPathURL = URL(string: caURLString + caUsersPath) else {
            throw ParseError(code: .otherCause,
                             message: "Could not create a url for \(caURLString + caUsersPath)")
        }
        self.caRootCertificateURL = caRootCertificateURL
        self.caCertificatesURL = caCertificatesURL
        self.caUsersPathURL = caUsersPathURL
    }

}
