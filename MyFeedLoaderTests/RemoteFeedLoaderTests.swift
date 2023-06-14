//
//  RemoteFeedLoaderTests.swift
//  MyFeedLoaderTests
//
//  Created by Akshay  on 2023-06-07.
//

import XCTest
import MyFeedLoader

class RemoteFeedLoaderTests: XCTestCase {
    
    func test_doesNotRequestDataFromURL() {
        
        let (_ , client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_requestsDataFromURL() {
        
        let url = URL(string: "https://given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load {_ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_requestsDataFromURLTwice() {
        
        let url = URL(string: "https://given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load {_ in }
        sut.load {_ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        
        let (sut, client) = makeSUT()
        
        expect(sut, completeWith: .failure(.connectivity)) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        
        let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            expect(sut, completeWith: .failure(.invalidData), when: {
                let json = makeItemJson([])
                client.complete(withStatusCode: code, data: json, at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidResponse() {
        
        let (sut, client) = makeSUT()
        
        expect(sut, completeWith: .failure(.invalidData), when: {
            let invalidJson = Data( _: "Invalid Json".utf8)
            client.complete(withStatusCode: 200, data: invalidJson)
        })
    }
    
    func test_load_deliversNoItemOn200HTTPResponseWithEmptyJSONArray() {
        
        let (sut, client) = makeSUT()
        
        expect(sut, completeWith: .success([]), when: {
            let emptyListJSON = makeItemJson([])
            client.complete(withStatusCode: 200, data: emptyListJSON)
        })
    }
    
    func test_load_deliversItemsOn200HTTPWithJsonArray() {
        
        let (sut, client) =  makeSUT()
        
        let item1 = makeItem(
            id: UUID(),
            imageURL: URL(string: "https://image-string-1.com")!)
        
        let item2 = makeItem(
            id: UUID(),
            description: "description",
            location: "location",
            imageURL: URL(string: "https://image-string-2.com")!)
        
        let itemsJSON = [item1.json, item2.json]
        
        expect(sut, completeWith: .success([item1.model, item2.model]), when: {
            let json = makeItemJson(itemsJSON)
            client.complete(withStatusCode: 200, data: json)
        })
    }
    
    // MARK: - HELPERS
    
    private func makeSUT(url:URL = URL(string: "https://url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, completeWith result: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        
        var capturedResults = [RemoteFeedLoader.Result]()
        
        sut.load { capturedResults.append($0) }
        
        action()
        
        XCTAssertEqual(capturedResults, [result], file: file, line: line)
    }
    
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        
        let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        
        let json = [
            "id" : id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].reduce(into: [String: Any]()) { (acc, e) in
            if let value = e.value { acc[e.key] = value}
        }
        
        return (item, json)
    }
    
    private func makeItemJson( _ items: [[String: Any]]) -> Data {
        let items = ["items": items]
        
        return try! JSONSerialization.data(withJSONObject: items)
    }
    
    private class HTTPClientSpy: HTTPClient {
        
        private var messages = [(url: URL, completion: (HTTPClientResponse) -> Void)]()
        var requestedURLs: [URL] {
            return messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping(HTTPClientResponse) -> Void) {
            
            messages.append((url,completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil)!
            
            messages[index].completion(.success(data, response))
        }
    }
}
