//
//  ParseCertificatable.swift
//  
//
//  Created by Corey Baker on 1/27/23.
//

import Foundation
import ParseSwift

/**
 Objects that conform to the `ParseCertificatable` protocol are
 `ParseObject`'s that have special properties and methods to support
 certificates and communicating with a
 [ca-server](https://github.com/netreconlab/ca-server).
 */
public protocol ParseCertificatable: ParseObject, Certificatable { }

public extension ParseCertificatable {

    /**
     Get/create certificates if an object is missing them.
     - parameter user: The `ParseUser` conforming user to create the certificate for.
     - parameter createUserAccountIfNeeded: If **true**, attempts to create an account for the `user` if the account currently does not exist. If **false** and the account does not exist, will throw an error. Defaults to **true**.
     - returns: A tuple where the first item is the user certificate and the second item is the root certificate.
     - throws: An error of `ParseError` type.
     - note: This is useful when certificates need to be created for the first time. If an object
     already has both certificates, it will simply return the current certificates.
     */
    func getCertificates<T>(_ user: T?,
                            createUserAccountIfNeeded: Bool = true) async throws -> (String?, String?) where T: ParseUser {
        try await getCertificates(user?.objectId,
                                  createUserAccountIfNeeded: createUserAccountIfNeeded)
    }

    /**
     Requests new certificates without checking to see if an object already has them.
     - parameter user: The `ParseUser` conforming user to create the certificate for.
     - parameter createUserAccountIfNeeded: If **true**, attempts to create an account for the `user` if the account currently does not exist. If **false** and the account does not exist, will throw an error. Defaults to **false**.
     - returns: A tuple where the first item is the user certificate and the second item is the root certificate.
     - throws: An error of `ParseError` type.
     - note: This is useful for when certificates have expired.
     */
    func requestNewCertificates<T>(_ user: T?,
                                   createUserAccountIfNeeded: Bool = false) async throws -> (String?, String?) where T: ParseUser {
        try await requestNewCertificates(user?.objectId,
                                         createUserAccountIfNeeded: createUserAccountIfNeeded)
    }

}
