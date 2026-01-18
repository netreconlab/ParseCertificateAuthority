//
//  Enums.swift
//  
//
//  Created by Corey Baker on 1/27/23.
//

import Foundation

enum RestMethod: String, Hashable, Sendable {
    case GET
    case POST
    case PUT
}

enum CertificateType: String, Hashable, Sendable {
    case root
    case user
}
