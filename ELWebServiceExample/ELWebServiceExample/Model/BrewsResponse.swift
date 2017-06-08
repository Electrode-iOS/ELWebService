//
//  BrewsResponse.swift
//  ELWebServiceExample
//
//  Created by Angelo Di Paolo on 6/7/17.
//  Copyright © 2017 WalmartLabs. All rights reserved.
//

import Foundation

struct BrewsResponse: Codable {
    let brews: [Brew]
}
