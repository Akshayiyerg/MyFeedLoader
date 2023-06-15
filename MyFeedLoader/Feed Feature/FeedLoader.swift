//
//  FeedLoader.swift
//  MyFeedLoader
//
//  Created by Akshay  on 2023-06-06.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

protocol FeedLoader {
    func load(completion: @escaping(LoadFeedResult) -> Void)
}
