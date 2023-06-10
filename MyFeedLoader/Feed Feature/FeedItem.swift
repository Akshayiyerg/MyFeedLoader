//
//  FeedItem.swift
//  MyFeedLoader
//
//  Created by Akshay  on 2023-06-06.
//

import Foundation


public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}
