//
//  URLSessionHTTPClientTests.swift
//  MyFeedLoaderTests
//
//  Created by Akshay  on 2023-06-15.
//

import Foundation
import XCTest
import MyFeedLoader

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    struct unexpextedError: Error {}
    
    func get(from url: URL, completion: @escaping (HTTPClientResponse) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(unexpextedError()))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        URLProtocolStub.startInterceptiongRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        
        URLProtocolStub.stopInterceptiongRequests()
    }
    
    func test_getFromURL_performGETRequestWithURL() {
        
        let url = anyURL()
        let exp = expectation(description: "wait for the request")
        
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        makeSUT().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsFromRequestError() {
        
        let requestError = NSError(domain: "any error", code: 1)
        
        var receivedError = resultErrorFor(data: nil, response: nil, error: requestError) as NSError?
        
        XCTAssertEqual(receivedError?.domain, requestError.domain)
        // Additional options to test
        /* XCTAssertEqual(receivedError.code, error.code)
         XCTAssertNotNil(receivedError) */
    }
    
    func test_getFromURL_failsFromAllNilValues() {
        
        let anyData = Data( _:"any data".utf8)
        let anyError = NSError(domain: "any Error", code: 0)
        let nonHTTPURLResponse = URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let anyHTTPURLResponse = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)
        
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: anyHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPURLResponse, error: nil))
    }
    
    // MARK: - Helpers
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {
        
        URLProtocolStub.stub(data: data, response: response, error: error)
        
        let exp = expectation(description: "Wait for the block")
        var receviedError: Error?
        var sut = makeSUT(file: file, line: line)
        
        sut.get(from: anyURL()) { result in
            switch result {
            case let .failure(error as NSError):
                receviedError = error
            default:
                XCTFail("Expected failure with error, \(result) instead")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return receviedError
    }
    
    private func anyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private class URLProtocolStub: URLProtocol {
        
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        static func startInterceptiongRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptiongRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response ,error: error)
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {
            
        }
    }
}
