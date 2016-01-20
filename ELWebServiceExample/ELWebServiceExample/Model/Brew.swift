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
 
    static func decode(json: AnyObject) -> Brew? {
        guard let name = json["name"] as? String else { return nil }
        guard let style = json["style"] as? String else { return nil }

        var brew = Brew(name: name, style: style)
        
        if let breweryJSON = json["brewery"],
            let wtf = breweryJSON {
            brew.brewery = Brewery.decode(wtf)
        }
        
        return brew
    }
}

extension Brew {
    
    var webServiceParameters: [String: AnyObject] {
        var params: [String: AnyObject] = ["name": name, "style": style]
        
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
