//
//  URLSessionHTTPClient.swift
//  MyFeedLoader
//
//  Created by Akshay  on 2023-06-19.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    private struct unexpextedError: Error {}
    
    public func get(from url: URL, completion: @escaping (HTTPClientResponse) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse{
                completion(.success(data, (response)))
            } else {
                completion(.failure(unexpextedError()))
            }
        }.resume()
    }
}
