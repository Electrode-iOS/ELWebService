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
    var webService: WebService { get }
    
    func fetchBrew(brewID: String) -> SessionTask
    func fetchAllBrews() -> SessionTask
    func save(brew: Brew) -> SessionTask
}

/// Implements the web services for the HTTP client methods
extension BrewClientAPI {
    func fetchBrew(brewID: String) -> SessionTask {
        let request = webService.request(.GET, path: "/brews")
        return sessionTask(request: request)
    }
    
    func fetchAllBrews() -> SessionTask {
        let request = webService.request(.GET, path: "/brews")
        return sessionTask(request: request)
    }
    
    func save(brew: Brew) -> SessionTask {
        var request = webService.request(.POST, path: "/brews")
        request.formParameters = brew.webServiceParameters
        return webService.serviceTask(request: request)
    }
    
    func sessionTask(request: URLRequestEncodable) -> SessionTask {
        return webService.sessionTask(request: request)
    }
}
