//
//  BrewClient.swift
//  SwallowExample
//
//  Created by Angelo Di Paolo on 9/22/15.
//  Copyright © 2015 TheHolyGrail. All rights reserved.
//

import THGWebService

final class BrewClient: BrewClientAPI {
    static let baseURL = "http://brewhapi.herokuapp.com/"
    let webService = WebService(baseURLString: baseURL)
}
