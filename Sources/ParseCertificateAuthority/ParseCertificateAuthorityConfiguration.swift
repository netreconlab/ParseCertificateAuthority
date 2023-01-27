//
//  ParseCertificateAuthorityConfiguration.swift
//  
//
//  Created by Corey Baker on 1/27/23.
//

import Foundation
import ParseSwift

public struct ParseCertificateAuthorityConfiguration {
    public internal(set) var caRootCertificateURL: URL
    public internal(set) var caCertificatesURL: URL
    public internal(set) var caUsersPathURL: URL

    public init(caURLString: String,
                caRootCertificatePath: String = "/ca_certificate",
                caCertificatesPath: String = "/certificates/",
                caUsersPath: String = "/appusers/") throws {
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
