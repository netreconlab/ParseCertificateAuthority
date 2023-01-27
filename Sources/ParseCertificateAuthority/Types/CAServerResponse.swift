//
//  CAResponse.swift
//  
//
//  Created by Corey Baker on 1/25/23.
//

import Foundation

struct CAServerResponse: Decodable {
    var certificateId: String
    var csr: String
    var certificate: String
    var user: String
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case csr, certificate
        case certificateId = "certificate_id"
        case user = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
