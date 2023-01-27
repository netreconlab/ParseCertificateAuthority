//
//  ParseCertificatable.swift
//  
//
//  Created by Corey Baker on 1/27/23.
//

import Foundation
import ParseSwift

/**
 Objects that conform to the `ParseCertificatable` protocol have special properties to
 support certificates.
 */
public protocol ParseCertificatable: ParseObject {
    /// The root certificate that signed the `csr` and turned it into a `certificate`.
    var rootCertificate: String? { get set }

    /// The certifcate made from the `csr`.
    var certificate: String? { get set }

    /// The CSR used to make the `certifcate`
    var csr: String? { get set }

    /// The unique identifier for the certificate
    var certificateId: String? { get }
}
