//
//  Brewery.swift
//  ELWebServiceExample
//
//  Created by Angelo Di Paolo on 9/30/15.
//  Copyright © 2015 WalmartLabs. All rights reserved.
//

import Foundation

struct Brewery: Codable {
    var name: String
    var location: String?
    
    init(name: String) {
        self.name = name
    }
}

