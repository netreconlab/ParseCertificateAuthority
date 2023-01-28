//
//  ParseCertificateAuthority.swift
//  Assuage
//
//  Created by Esther Max-Onakpoya on 8/19/22.
//  Copyright © 2022 NetReconLab. All rights reserved.
//

import Foundation
import ParseSwift

// MARK: Configure Framework

/// Initialize the framework with a specific confguration.
/// - parameter configuration: The configuration to use for the framework.
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
