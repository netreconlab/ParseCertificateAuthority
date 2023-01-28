# ParseCertificateAuthority

Send CSR's and retreive certificates to/from `ca-server` from [Parse-Swift](https://github.com/netreconlab/Parse-Swift) based clients and servers.

---

## Software Designed for `ca-server`
- [ca-server](https://github.com/netreconlab/ParseCertificateAuthority) - A certificate authority(CA) that can turn CSR's into certificates
- [CertificateSigningRequest](https://github.com/cbaker6/CertificateSigningRequest) - Generate CSR's on Swift clients and servers that can later be signed by `ca-server`
- [Parse-Swift](https://github.com/netreconlab/Parse-Swift) - Write Parse client apps in Swift. When coupled with - [ParseCertificateAuthority](https://github.com/netreconlab/ParseCertificateAuthority) and - [CertificateSigningRequest](https://github.com/cbaker6/CertificateSigningRequest), provides the complete client-side stack for generating CSR's, sending/receiving certificates to/from `ca-server`
- [ParseServerSwift](https://github.com/netreconlab/parse-server-swift) - Write Parse Server Cloud Code apps in Swift. When coupled with - [ParseCertificateAuthority](https://github.com/netreconlab/ParseCertificateAuthority), [CertificateSigningRequest](https://github.com/cbaker6/CertificateSigningRequest), and [Parse-Swift](https://github.com/netreconlab/Parse-Swift) provides the complete server-side stack for generating CSR's, sending/receiving certificates to/from `ca-server`

## Adding `ParseCertificateAuthority` to Your App
Setup a Vapor project by following the [directions](https://www.kodeco.com/11555468-getting-started-with-server-side-swift-with-vapor-4) for installing and setting up your project on macOS or linux.

In your `Package.swift` file add `ParseCertificateAuthority` to `dependencies`:

```swift
// swift-tools-version:5.5.2
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
        .package(url: "https://github.com/netreconlab/ParseCertificateAuthority", .upToNextMajor(from: "0.0.1")),
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

## Choosing a `ParseObject` Model to Conform to `ParseCertificatable`
At least one of your `ParseObject` models need to conform to `ParseCertificatable`. A good candidate is a model that already conforms to `ParseInstallatiion` as this is unique per installation on each device.

```swift
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
Once you have a CSR from a package like [CertificateSigningRequest](https://github.com/cbaker6/CertificateSigningRequest), you can create an account for the current `ParseUser` and send it to a [ca-server](https://github.com/netreconlab/ParseCertificateAuthority)
