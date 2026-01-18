//
//  CAServerBody.swift
//  
//
//  Created by Corey Baker on 1/27/23.
//

import Foundation

struct CAServerBody: Codable, Hashable, Sendable {
    var user: String
    var certificateId: String?
    var csr: String?
}
