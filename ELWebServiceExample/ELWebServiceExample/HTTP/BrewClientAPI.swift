//
//  BrewClientAPI.swift
//  ELWebServiceExample
//
//  Created by Angelo Di Paolo on 9/22/15.
//  Copyright © 2015 WalmartLabs. All rights reserved.
//

import ELWebService

/// Describes the brew client API
protocol BrewClientAPI {
    var service: WebService { get }
    
    func fetchBrew(brewID: String) -> ServiceTask
    func fetchAllBrews() -> ServiceTask
    func insert(brew: Brew) -> ServiceTask
}

/// Implements the web services for the HTTP client methods
extension BrewClientAPI {
    func fetchBrew(brewID: String) -> ServiceTask {
        return service.GET("/brews/\(brewID)")
    }
    
    func fetchAllBrews() -> ServiceTask {
        return service.GET("/brews")
    }
    
    func insertRequest(brew: Brew) -> ServiceRequest {
        var request = service.request(.post, "/brews")
        request.formParameters = brew.webServiceParameters
        return request
    }
    
    func insert(brew: Brew) -> ServiceTask {
        return service.task(request: insertRequest(brew: brew))
    }
}
