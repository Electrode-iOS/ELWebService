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
    static func decode(_ json: Any) -> Brewery? {
        guard
            let dictionary = json as? [String: Any],
            let name = dictionary["name"] as? String
            else {
                return nil
        }
        
        var brewery = Brewery(name: name)
        brewery.location = dictionary["location"] as? String
        return brewery
    }
}
