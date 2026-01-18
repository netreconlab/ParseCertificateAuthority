// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ParseCertificateAuthority",
    platforms: [
        .iOS(.v13),
        .macCatalyst(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "ParseCertificateAuthority",
            targets: ["ParseCertificateAuthority"]
		)
    ],
    dependencies: [
        .package(
			url: "https://github.com/netreconlab/Parse-Swift.git",
			.upToNextMajor(from: "6.0.0")
		)
    ],
    targets: [
        .target(
            name: "ParseCertificateAuthority",
            dependencies: [
                .product(
					name: "ParseSwift",
					package: "Parse-Swift"
				)
            ]
        ),
        .testTarget(
            name: "ParseCertificateAuthorityTests",
            dependencies: ["ParseCertificateAuthority"]
		)
    ]
)
