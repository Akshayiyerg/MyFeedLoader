//
//  HTTPClient.swift
//  MyFeedLoader
//
//  Created by Akshay  on 2023-06-14.
//

import Foundation

public enum HTTPClientResponse {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    
    func get(from url: URL, completion: @escaping(HTTPClientResponse) -> Void)
}
