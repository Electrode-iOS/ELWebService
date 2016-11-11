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
    
    func fetchBrew(brewID: String) -> ServiceTask
    func fetchAllBrews() -> ServiceTask
    func save(brew: Brew) -> ServiceTask
}

/// Implements the web services for the HTTP client methods
extension BrewClientAPI {
    func fetchBrew(brewID: String) -> ServiceTask {
        return webService.GET("/brews/\(brewID)")
    }
    
    func fetchAllBrews() -> ServiceTask {
        return webService.GET("/brews")
    }
    
    func save(brew: Brew) -> ServiceTask {
        return webService.POST("/brews").setFormParameters(brew.webServiceParameters)
    }
}
