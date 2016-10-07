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
    
    func fetchBrewWithBrewID(brewID: String) -> ServiceTask
    func fetchAllBrews() -> ServiceTask
    func insertBrew(brew: Brew) -> ServiceTask
}

/// Implements the web services for the HTTP client methods
extension BrewClientAPI {
    
    func fetchBrewWithBrewID(brewID: String) -> ServiceTask {
        return webService.GET("/brews/\(brewID)")
    }
    
    func fetchAllBrews() -> ServiceTask {
        return webService.GET("/brews")
    }
    
    func insertBrew(brew: Brew) -> ServiceTask {
        return webService.POST("/brews").setFormParameters(brew.webServiceParameters)
    }
}
