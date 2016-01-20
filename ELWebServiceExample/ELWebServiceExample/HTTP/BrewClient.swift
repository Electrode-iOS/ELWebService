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
