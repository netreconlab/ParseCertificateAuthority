import XCTest
@testable import ParseCertificateAuthority
import ParseSwift

// swiftlint:disable:next type_body_length
final class ParseCertificateAuthorityTests: XCTestCase {

    struct Installation: ParseInstallation, ParseCertificatable {

        // These are required by ParseCertificatable
        var rootCertificate: String?
        var certificate: String?
        var csr: String?
        var certificateId: String?

        // These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        // These are required by ParseObject
        var deviceType: String?
        var installationId: String?
        var deviceToken: String?
        var badge: Int?
        var timeZone: String?
        var channels: [String]?
        var appName: String?
        var appIdentifier: String?
        var appVersion: String?
        var parseVersion: String?
        var localeIdentifier: String?
    }

    struct User: ParseUser {

        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        // These are required by ParseUser
        var username: String?
        var email: String?
        var emailVerified: Bool?
        var password: String?
        var authData: [String: [String: String]?]?

    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        let configuration = try ParseCertificateAuthorityConfiguration(caURLString: "http://certificate-authority:3000",
                                                                       caRootCertificatePath: "/ca_certificate",
                                                                       caCertificatesPath: "/certificates/",
                                                                       caUsersPath: "/appusers/")
        ParseCertificateAuthority.initialize(configuration: configuration)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
    }

    func testConfigureFramework() throws {
        XCTAssertEqual(configuration.caRootCertificateURL,
                       URL(string: "http://certificate-authority:3000/ca_certificate"))
        XCTAssertEqual(configuration.caCertificatesURL,
                       URL(string: "http://certificate-authority:3000/certificates/"))
        XCTAssertEqual(configuration.caUsersPathURL,
                       URL(string: "http://certificate-authority:3000/appusers/"))
        XCTAssertNoThrow(try ParseCertificateAuthorityConfiguration(caURLString: "http://certificate-authority:3000",
                                                                    caRootCertificatePath: "/ca_certificate",
                                                                    caCertificatesPath: "/certificates/",
                                                                    caUsersPath: "/appusers/"))
    }

    func testConfigureFrameworkBadRootPath() throws {
        // swiftlint:disable:next line_length
        XCTAssertThrowsError(try ParseCertificateAuthorityConfiguration(caURLString: "http://certificate-authority:3000",
                                                                        caRootCertificatePath: " - $",
                                                                        caCertificatesPath: "/certificates/",
                                                                        caUsersPath: "/appusers/"))
    }

    func testConfigureFrameworkBadCertPath() throws {
        // swiftlint:disable:next line_length
        XCTAssertThrowsError(try ParseCertificateAuthorityConfiguration(caURLString: "http://certificate-authority:3000",
                                                                        caRootCertificatePath: "/ca_certificate",
                                                                        caCertificatesPath: " - $",
                                                                        caUsersPath: "/appusers/"))
    }

    func testConfigureFrameworkBadUserPath() throws {
        // swiftlint:disable:next line_length
        XCTAssertThrowsError(try ParseCertificateAuthorityConfiguration(caURLString: "http://certificate-authority:3000",
                                                                        caRootCertificatePath: "/ca_certificate",
                                                                        caCertificatesPath: "/certificates/",
                                                                        caUsersPath: " - $"))
    }

    func testHasCertificate() async throws {
        var object = Installation()
        XCTAssertFalse(object.hasCertificate())
        XCTAssertFalse(object.hasRootCertificate())
        XCTAssertNil(object.certificateId)
        XCTAssertNil(object.csr)
        object.certificate = "yolo"
        XCTAssertTrue(object.hasCertificate())
        XCTAssertFalse(object.hasRootCertificate())
        XCTAssertNil(object.certificateId)
        XCTAssertNil(object.csr)
    }

    func testHasRootCertificate() async throws {
        var object = Installation()
        XCTAssertFalse(object.hasCertificate())
        XCTAssertFalse(object.hasRootCertificate())
        XCTAssertNil(object.certificateId)
        XCTAssertNil(object.csr)
        object.rootCertificate = "yolo"
        XCTAssertFalse(object.hasCertificate())
        XCTAssertTrue(object.hasRootCertificate())
        XCTAssertNil(object.certificateId)
        XCTAssertNil(object.csr)
    }

    func testGetCertificatesNoUser() async throws {
        var object = Installation()
        object.csr = "whoa"
        object.certificateId = "hella"
        do {
            _ = try await object.getCertificates(User())
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Missing"))
        }
    }

    func testGetCertificatesNoCSR() async throws {
        var object = Installation()
        object.csr = nil
        object.certificateId = "hella"
        var user = User()
        user.objectId = "peace"
        do {
            _ = try await object.getCertificates(user)
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Missing"))
        }
    }

    func testGetCertificatesNoCertificateId() async throws {
        var object = Installation()
        object.csr = "whoa"
        object.certificateId = nil
        var user = User()
        user.objectId = "peace"
        do {
            _ = try await object.getCertificates(user)
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Missing"))
        }
    }

    func testGetCertificatesHasCertificateAndRoot() async throws {
        var object = Installation()
        object.csr = "whoa"
        object.certificateId = "hella"
        object.certificate = "maybe"
        object.rootCertificate = "not"
        var user = User()
        user.objectId = "peace"
        let updated = try await object.getCertificates(user)
        XCTAssertEqual(updated.0, object.certificate)
        XCTAssertEqual(updated.1, object.rootCertificate)
    }

    func testGetCertificates() async throws {
        let csr = "whoa"
        let certificateId = "hella"
        let userId = "peace"
        var object = Installation()
        object.csr = csr
        object.certificateId = certificateId
        var user = User()
        user.objectId = userId

        let objectOnServer = CAServerBody(user: userId,
                                          certificateId: certificateId,
                                          csr: csr)
        let encoded: Data!
        do {
            encoded = try object.getJSONEncoder().encode(objectOnServer)
        } catch {
            XCTFail("Should encoded. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        do {
            _ = try await object.getCertificates(user)
        } catch {
            #if !os(Linux) && !os(Android) && !os(Windows)
            let nsError = error as NSError
            XCTAssertTrue(nsError.userInfo.description.contains("Expected to decode String"))
            #endif
        }
    }

    func testRequestNewCertificatesNoUser() async throws {
        var object = Installation()
        object.csr = "whoa"
        object.certificateId = "hella"
        do {
            _ = try await object.requestNewCertificates(User())
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Missing"))
        }
    }

    func testRequestNewCertificatesNoCSR() async throws {
        var object = Installation()
        object.csr = nil
        object.certificateId = "hella"
        var user = User()
        user.objectId = "peace"
        do {
            _ = try await object.requestNewCertificates(user)
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Missing"))
        }
    }

    func testRequestNewCertificatesNoCertificateId() async throws {
        var object = Installation()
        object.csr = "whoa"
        object.certificateId = nil
        var user = User()
        user.objectId = "peace"
        do {
            _ = try await object.requestNewCertificates(user)
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Missing"))
        }
    }

    func testRequestNewCertificatesHasCertificateAndRoot() async throws {
        let csr = "whoa"
        let certificateId = "hella"
        let userId = "peace"
        var object = Installation()
        object.csr = csr
        object.certificateId = certificateId
        object.certificate = "maybe"
        object.rootCertificate = "not"
        var user = User()
        user.objectId = userId

        let objectOnServer = CAServerBody(user: userId,
                                          certificateId: certificateId,
                                          csr: csr)
        let encoded: Data!
        do {
            encoded = try object.getJSONEncoder().encode(objectOnServer)
        } catch {
            XCTFail("Should encoded. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        do {
            _ = try await object.requestNewCertificates(user)
        } catch {
            #if !os(Linux) && !os(Android) && !os(Windows)
            let nsError = error as NSError
            XCTAssertTrue(nsError.userInfo.description.contains("Expected to decode String"))
            #endif
        }
    }

    func testRequestNewCertificates() async throws {
        let csr = "whoa"
        let certificateId = "hella"
        let userId = "peace"
        var object = Installation()
        object.csr = csr
        object.certificateId = certificateId
        var user = User()
        user.objectId = userId

        let objectOnServer = CAServerBody(user: userId,
                                          certificateId: certificateId,
                                          csr: csr)
        let encoded: Data!
        do {
            encoded = try object.getJSONEncoder().encode(objectOnServer)
        } catch {
            XCTFail("Should encoded. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        do {
            _ = try await object.requestNewCertificates(user)
        } catch {
            #if !os(Linux) && !os(Android) && !os(Windows)
            let nsError = error as NSError
            XCTAssertTrue(nsError.userInfo.description.contains("Expected to decode String"))
            #endif
        }
    }

    func testRestfullCertificatesNoPostRoot() async throws {
        let csr = "whoa"
        let certificateId = "hella"
        let userId = "peace"
        var object = Installation()
        object.csr = csr
        object.certificateId = certificateId

        do {
            let body = CAServerBody(user: userId,
                                    certificateId: certificateId,
                                    csr: csr)
            _ = try await object.restfullCertificates(httpMethod: .POST,
                                                      body: body,
                                                      certificateType: .root,
                                                      certificateId: nil)
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("Can only GET Root"))
        }
    }

    func testRestfullCertificatesNoPutRoot() async throws {
        let csr = "whoa"
        let certificateId = "hella"
        let userId = "peace"
        var object = Installation()
        object.csr = csr
        object.certificateId = certificateId

        do {
            let body = CAServerBody(user: userId,
                                    certificateId: certificateId,
                                    csr: csr)
            _ = try await object.restfullCertificates(httpMethod: .PUT,
                                                      body: body,
                                                      certificateType: .root,
                                                      certificateId: nil)
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("Can only GET Root"))
        }
    }

    func testRestfullCertificatesGETRoot() async throws {
        let csr = "whoa"
        let certificateId = "hella"
        let userId = "peace"
        let certificate = "we made it"
        let createdAt = "then"
        let updatedAt = "now"
        var object = Installation()
        object.csr = csr
        object.certificateId = certificateId
        var user = User()
        user.objectId = userId

        let objectOnServer = CAServerResponse(user: userId,
                                              certificateId: certificateId,
                                              csr: csr,
                                              certificate: certificate,
                                              createdAt: createdAt,
                                              updatedAt: updatedAt)

        let encoded: Data!
        do {
            encoded = try object.getJSONEncoder().encode(objectOnServer)
        } catch {
            XCTFail("Should encoded. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let body = CAServerBody(user: userId,
                                certificateId: certificateId,
                                csr: csr)
        let updatedCertificate = try await object.restfullCertificates(httpMethod: .GET,
                                                                       body: body,
                                                                       certificateType: .root,
                                                                       certificateId: nil)
        XCTAssertEqual(updatedCertificate, certificate)
    }

    func testRestfullCertificatesPOSTCert() async throws {
        let csr = "whoa"
        let certificateId = "hella"
        let userId = "peace"
        let certificate = "we made it"
        let createdAt = "then"
        let updatedAt = "now"
        var object = Installation()
        object.csr = csr
        object.certificateId = certificateId
        var user = User()
        user.objectId = userId

        let objectOnServer = CAServerResponse(user: userId,
                                              certificateId: certificateId,
                                              csr: csr,
                                              certificate: certificate,
                                              createdAt: createdAt,
                                              updatedAt: updatedAt)

        let encoded: Data!
        do {
            encoded = try object.getJSONEncoder().encode(objectOnServer)
        } catch {
            XCTFail("Should encoded. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let body = CAServerBody(user: userId,
                                certificateId: certificateId,
                                csr: csr)
        let updatedCertificate = try await object.restfullCertificates(httpMethod: .POST,
                                                                       body: body,
                                                                       certificateType: .user,
                                                                       certificateId: nil)
        XCTAssertEqual(updatedCertificate, certificate)
    }

    func testRestfullCertificatesPUTCert() async throws {
        let csr = "whoa"
        let certificateId = "hella"
        let userId = "peace"
        let certificate = "we made it"
        let createdAt = "then"
        let updatedAt = "now"
        var object = Installation()
        object.csr = csr
        object.certificateId = certificateId
        var user = User()
        user.objectId = userId

        let objectOnServer = CAServerResponse(user: userId,
                                              certificateId: certificateId,
                                              csr: csr,
                                              certificate: certificate,
                                              createdAt: createdAt,
                                              updatedAt: updatedAt)

        let encoded: Data!
        do {
            encoded = try object.getJSONEncoder().encode(objectOnServer)
        } catch {
            XCTFail("Should encoded. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let body = CAServerBody(user: userId,
                                certificateId: certificateId,
                                csr: csr)
        let updatedCertificate = try await object.restfullCertificates(httpMethod: .PUT,
                                                                       body: body,
                                                                       certificateType: .user,
                                                                       certificateId: certificateId)
        XCTAssertEqual(updatedCertificate, certificate)
    }

    func testVerifyAndCreateUserOnCAErrorCreate() async throws {
        let csr = "whoa"
        let certificateId = "hella"
        let userId = "peace"
        var object = Installation()
        object.csr = csr
        object.certificateId = certificateId
        var user = User()
        user.objectId = userId

        let objectOnServer = user // Force error

        let encoded: Data!
        do {
            encoded = try object.getJSONEncoder().encode(objectOnServer)
        } catch {
            XCTFail("Should encoded. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 500)
        }

        do {
            try await object.verifyAndCreateUserOnCA(userId: userId,
                                                     createUserAccountIfNeeded: true)
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("500"))
        }
    }

    func testVerifyAndCreateUserOnCAErrorDoNotCreate() async throws {
        let csr = "whoa"
        let certificateId = "hella"
        let userId = "peace"
        var object = Installation()
        object.csr = csr
        object.certificateId = certificateId
        var user = User()
        user.objectId = userId

        let objectOnServer = user // Force error

        let encoded: Data!
        do {
            encoded = try object.getJSONEncoder().encode(objectOnServer)
        } catch {
            XCTFail("Should encoded. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 500)
        }

        do {
            try await object.verifyAndCreateUserOnCA(userId: userId,
                                                     createUserAccountIfNeeded: false)
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("500"))
        }
    }

}
