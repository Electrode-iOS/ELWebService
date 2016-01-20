//
//  Brewery.swift
//  ELWebServiceExample
//
//  Created by Angelo Di Paolo on 9/30/15.
//  Copyright © 2015 WalmartLabs. All rights reserved.
//

import Foundation

struct Brewery {
    var name: String
    var location: String?
    
    init(name: String) {
        self.name = name
    }
}

extension Brewery: ModelDecodable {
    
    static func decode(json: AnyObject) -> Brewery? {
        guard let name = json["name"] as? String else { return nil }
        
        var brewery = Brewery(name: name)
        brewery.location = json["location"] as? String
        return brewery
    }
}
