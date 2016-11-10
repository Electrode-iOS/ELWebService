//
//  SessionDataTaskDataSource.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 11/3/15.
//  Copyright © 2015 WalmartLabs. All rights reserved.
//

import Foundation

///**
// Types conforming to the `SessionDataTaskDataSource` protocol are responsible
// for creating `NSURLSessionDataTask` objects based on a `NSURLRequest` value
// and invoking a completion handler after the response of a data task has been
// received. Adopt this protocol in order to specify the `NSURLSession` instance
// used to send requests.
// */
//public protocol SessionDataTaskDataSource: class, Session {
//    func dataTask(request: NSURLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
//}
//
//extension SessionDataTaskDataSource {
//    func dataTask(request: URLRequestEncodable, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> DataTask {
//        return dataTask(request: request.urlRequestValue as NSURLRequest, completionHandler: completion)
//    }
//}
//
//extension URLSession: SessionDataTaskDataSource {}
