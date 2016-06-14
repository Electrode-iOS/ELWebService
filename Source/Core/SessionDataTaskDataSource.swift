//
//  SessionDataTaskDataSource.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 11/3/15.
//  Copyright © 2015 WalmartLabs. All rights reserved.
//

import Foundation

/**
 Types conforming to the `SessionDataTaskDataSource` protocol are responsible
 for creating `NSURLSessionDataTask` objects based on a `NSURLRequest` value
 and invoking a completion handler after the response of a data task has been
 received. Adopt this protocol in order to specify the `NSURLSession` instance
 used to send requests.
 */
public protocol SessionDataTaskDataSource: class, Session {
    func dataTaskWithRequest(_ request: URLRequest, completionHandler: (Data?, URLResponse?, NSError?) -> Void) -> URLSessionDataTask
}

extension SessionDataTaskDataSource {
    func dataTask(request: URLRequestEncodable, completion: (Data?, URLResponse?, NSError?) -> Void) -> DataTask {
        return dataTaskWithRequest(request.urlRequestValue as URLRequest, completionHandler: completion)
    }
}

extension URLSession: SessionDataTaskDataSource {}
