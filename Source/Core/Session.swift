//
//  Session.swift
//  THGWebService
//
//  Created by Andrew Finnell on 10/15/15.
//  Copyright © 2015 TheHolyGrail. All rights reserved.
//

import Foundation

/**
    Types conforming to the `SessionDataTaskDataSource` protocol are responsible
    for creating `NSURLSessionDataTask` objects based on a `NSURLRequest` value
    and invoking a completion handler after the response of a data task has been
    received. Adopt this protocol in order to specify the `NSURLSession` instance
    used to send requests.
*/
public protocol SessionDataTaskDataSource {
    func dataTaskWithRequest(request: NSURLRequest, completion: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask?
}

public class Session {
    
    /**
    Set to `false` to prevent `ServiceTask` instances from resuming
    immediately.
    */
    public var startTasksImmediately = true

    public init(session: NSURLSession = NSURLSession.sharedSession()) {
        self.session = session
    }
    
    public func enqueue(urlRequestEncodable: URLRequestEncodable) -> ServiceTask {
        let task = ServiceTask(urlRequestEncodable: urlRequestEncodable, dataTaskSource: self)
        
        if startTasksImmediately {
            task.resume()
        }
        
        return task
    }
    
    private let session: NSURLSession
}

// MARK: - SessionDataTaskDataSource

extension Session: SessionDataTaskDataSource {
    public func dataTaskWithRequest(request: NSURLRequest, completion: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask? {
        return session.dataTaskWithRequest(request, completionHandler: completion);
    }
}
