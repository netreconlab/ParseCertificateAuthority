//
//  ParseCertificateAuthority.swift
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

internal struct ParseCA {
    static var configuration: ParseCertificateAuthorityConfiguration!
}
