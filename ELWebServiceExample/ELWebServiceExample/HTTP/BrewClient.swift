//
//  BrewClient.swift
//  ELWebServiceExample
//
//  Created by Angelo Di Paolo on 9/22/15.
//  Copyright © 2015 WalmartLabs. All rights reserved.
//

import ELWebService

final class BrewClient: BrewClientAPI {
    static let baseURL = "http://brewhapi.herokuapp.com/"
    let webService = WebService(baseURLString: baseURL)
}

final class Passthrough: ServicePassthroughDelegate {
    static let shared = Passthrough()
    
    /// Called before a request is to be sent
    func requestSent(_ request: URLRequest) {
        
    }
    
    /// Called after a NSURLSessionDataTask has completed
    func responseReceived(_ response: URLResponse?, data: Data?, request: URLRequest?, error: Error?) {
        
    }
    
    /// Called before an updateUI handler is invoked
    func updateUIBegin(_ response: URLResponse?) {
        
    }
    
    /// Called after an updateUI handler has been invoked
    func updateUIEnd(_ response: URLResponse?) {
        
    }
    
    /// Called when a ServiceTask handler returns a .Failure(error) result
    func serviceResultFailure(_ response: URLResponse?, data: Data?, request: URLRequest?, error: Error) {
        
    }
    
    func modifiedRequest(_ request: URLRequest) -> URLRequest? {
        return nil
    }
    
    func didFinishCollectingTaskMetrics(metrics: ServiceTaskMetrics, request: URLRequest, response: URLResponse?, error: Error?) {
        print("start time =\(String(describing: metrics.fetchStartDate?.timeIntervalSince1970))")
        print("end time =\(String(describing: metrics.responseEndDate?.timeIntervalSince1970))")
    }
}

extension WebService: ServicePassthroughDataSource {
    public var servicePassthroughDelegate: ServicePassthroughDelegate {
        return Passthrough.shared
    }
}
