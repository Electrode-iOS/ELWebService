//
//  Brew.swift
//  ELWebServiceExample
//
//  Created by Angelo Di Paolo on 9/22/15.
//  Copyright © 2015 WalmartLabs. All rights reserved.
//

import Foundation
import ELWebService

struct Brew {
    var name: String
    var style: String
    var brewery: Brewery?
    
    init(name: String, style: String) {
        self.name = name
        self.style = style
    }
}

extension Brew: ModelDecodable {
    static func decode(_ json: Any) -> Brew? {
        guard let dictionary = json as? [String: Any],
            let name = dictionary["name"] as? String,
            let style = dictionary["style"] as? String
        else {
            return nil
        }
        
        var brew = Brew(name: name, style: style)
        
        if let breweryJSON = dictionary["brewery"] {
            brew.brewery = Brewery.decode(breweryJSON)
        }
        
        return brew
    }
}

extension Brew {
    
    var webServiceParameters: [String: Any] {
        var params: [String: Any] = ["name": name, "style": style]
        
        if let brewery = brewery {
            if let location = brewery.location {
                params["brewery"] = ["name": brewery.name, "location": location]
            } else {
                params["brewery"] = ["name": brewery.name]
            }
        }
        
        return params
    }
}
