//
//  FeedLoader.swift
//  MyFeedLoader
//
//  Created by Akshay  on 2023-06-06.
//

import Foundation

enum LoaderFeedResult {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func loadFeed(completion: @escaping(LoaderFeedResult) -> Void)
}
