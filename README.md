# ParseCertificateAuthority

[![Documentation](http://img.shields.io/badge/read-docs-2196f3.svg)](https://swiftpackageindex.com/netreconlab/ParseCertificateAuthority/documentation)
[![Tuturiol](http://img.shields.io/badge/read-tuturials-2196f3.svg)](https://netreconlab.github.io/ParseCertificateAuthority/release/tutorials/parsecertificateauthority/)
[![ci](https://github.com/netreconlab/ParseCertificateAuthority/actions/workflows/ci.yml/badge.svg)](https://github.com/netreconlab/ParseCertificateAuthority/actions/workflows/ci.yml)
[![release](https://github.com/netreconlab/ParseCertificateAuthority/actions/workflows/release.yml/badge.svg)](https://github.com/netreconlab/ParseCertificateAuthority/actions/workflows/release.yml)
[![codecov](https://codecov.io/gh/netreconlab/ParseCertificateAuthority/branch/main/graph/badge.svg?token=RC3FLU6BGW)](https://codecov.io/gh/netreconlab/ParseCertificateAuthority)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://github.com/netreconlab/ParseCertificateAuthority/blob/main/LICENSE)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnetreconlab%2FParseCertificateAuthority%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/netreconlab/ParseCertificateAuthority)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnetreconlab%2FParseCertificateAuthority%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/netreconlab/ParseCertificateAuthority)

---

Send CSR's and retreive certificates to/from `ca-server`'s from your own Swift based client and server apps. `Certificatable` allows any object to support certificates while `ParseCertificatable` allows any [ParseObject](https://netreconlab.github.io/Parse-Swift/release/documentation/parseswift/parseobject) from [Parse-Swift](https://github.com/netreconlab/Parse-Swift). `ParseCertificateAuthority` helps developers add an extra layer of security to their apps by making it easy to enable certificate pinning, authentication/verification, encrypting/decrypting, and secure device-to-device offline communication with key/certificate exchange.

## `ParseCertificateAuthority` is Designed to Work With `ca-server`
- [ca-server](https://github.com/netreconlab/ParseCertificateAuthority) - A certificate authority(CA) that can turn CSR's into certificates
- [CertificateSigningRequest](https://github.com/cbaker6/CertificateSigningRequest) - Generate CSR's on Swift clients and servers that can later be signed by `ca-server`
- [Parse-Swift](https://github.com/netreconlab/Parse-Swift) - Write Parse client apps in Swift. When coupled with [ParseCertificateAuthority](https://github.com/netreconlab/ParseCertificateAuthority) and [CertificateSigningRequest](https://github.com/cbaker6/CertificateSigningRequest), provides the complete client-side stack for generating CSR's, sending/receiving certificates to/from `ca-server`
- [ParseServerSwift](https://github.com/netreconlab/parse-server-swift) - Write Parse Server Cloud Code apps in Swift. When coupled with [ParseCertificateAuthority](https://github.com/netreconlab/ParseCertificateAuthority), [CertificateSigningRequest](https://github.com/cbaker6/CertificateSigningRequest), and [Parse-Swift](https://github.com/netreconlab/Parse-Swift) provides the complete server-side stack for generating CSR's, sending/receiving certificates to/from `ca-server`

## Adding `ParseCertificateAuthority` to Your App
Setup a Vapor project by following the [directions](https://www.kodeco.com/11555468-getting-started-with-server-side-swift-with-vapor-4) for installing and setting up your project on macOS or linux.

In your `Package.swift` file add `ParseCertificateAuthority` to `dependencies`:

```swift
// swift-tools-version:5.5.2
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
        .package(url: "https://github.com/netreconlab/ParseCertificateAuthority", .upToNextMajor(from: "0.1.0")),
    ]
)
```

## Configure `ParseCertificateAuthority`
```swift
import ParseCertificateAuthority

// Innitialize ParseCertificateAuthority
let caConfiguration = try ParseCertificateAuthorityConfiguration(caURLString: "http://certificate-authority:3000", // The url for `ca-server`.
                                                                 caRootCertificatePath: "/ca_certificate", // The root certificate path on `ca-server`.
                                                                 caCertificatesPath: "/certificates/", // The certificates path on `ca-server`.
                                                                 caUsersPath: "/appusers/") // The user path on `ca-server`.
initialize(configuration: caConfiguration)
```

## Choosing an `Object` or `ParseObject` Model to Conform to `Certificatable` or `ParseCertificatable`
Below is an example of conforming to `ParseCertificatable` if you are using `Parse-Swift`. If you are not using `Parse-Swift`, the process is similar except you conform to `Certificatable` and use the relevant methods. At least one of your `ParseObject` models need to conform to `ParseCertificatable`. A good candidate is a model that already conforms to `ParseInstallatiion` as this is unique per installation on each device.

```swift
// Conform to `ParseCertificatable`. If not using Parse-Swift, conform to `Certificatable` instead.
struct Installation: ParseInstallation, ParseCertificatable {
    var rootCertificate: String?

    var certificate: String?

    var csr: String?
    
    var certificateId: String? {
        installationId
    }
    ...
}
```

## Creating a New Certificate From a CSR
Once you have a CSR from a package like [CertificateSigningRequest](https://github.com/cbaker6/CertificateSigningRequest), you can create an account for the current `ParseUser` automatically and send the CSR to a [ca-server](https://github.com/netreconlab/ParseCertificateAuthority) by doing the following:

```swift
do {
    let user = User.current // Some user type that conforms to `ParseUser`.
    var installation = Installation.current
    let (certificate, rootCertificate) = try await installation.getCertificates(user)
    if installation.certificate != certificate || installation.rootCertificate != rootCertificate {
        installation.certificate = certificate
        installation.rootCertificate = rootCertificate
        try await installation.save()
        
        // Notify the user their object has been updated with the certificates
    }
} catch {
    // Handle error
}
```

## Requesting a New Certificate Be Generated for an Existing CSR
Creating a new certificate for a CSR can be useful when a certificate has expired. To generage a new certificate, do the following:

```swift
do {
    let user = User.current // Some user type that conforms to `ParseUser`.
    var installation = Installation.current
    let (certificate, rootCertificate) = try await installation.requestNewCertificates(user)
    guard let certificate = certificate,
          let rootCertificate = rootCertificate else {
        let error = ParseError(code: .otherCause,
                               message: "Could not get new certificates")
        return
    }
    
    installation.certificate = certificate
    installation.rootCertificate = rootCertificate
    try await installation.save()
       
    // Notify the user their object has been updated with the certificates
} catch {
    // Handle error
}
```

