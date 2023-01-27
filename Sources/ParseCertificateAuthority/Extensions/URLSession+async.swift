//
//  URLSession+async.swift
//  
//
//  Created by Corey Baker on 1/26/23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import ParseSwift

extension URLSession {
    func dataTask(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            self.dataTask(with: request,
                          completionHandler: continuation.resume).resume()
        }
    }

    func dataTask(with request: URLRequest,
                  completionHandler: @escaping (Result<(Data, URLResponse), Error>) -> Void) -> URLSessionDataTask {
        return dataTask(with: request) { (data, response, error) in
            guard let data = data,
                  let response = response else {
                guard let error = error else {
                    let parseError = ParseError(code: .otherCause, message: "An unknown error occured")
                    completionHandler(.failure(parseError))
                    return
                }
                completionHandler(.failure(error))
                return
            }
            completionHandler(.success((data, response)))
        }
    }
}
