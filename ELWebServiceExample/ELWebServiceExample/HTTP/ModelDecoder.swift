//
//  JSONDecoder.swift
//  ELWebServiceExample
//
//  Created by Angelo Di Paolo on 9/30/15.
//  Copyright © 2015 WalmartLabs. All rights reserved.
//

import Foundation

protocol ModelDecodable {
    static func decode(_ json: Any) -> Self?
}

struct ModelDecoder<T: ModelDecodable> {
    static func decode(_ json: Any) -> T? {
        return T.decode(json)
    }
    
    static func decodeArray(_ json: [Any]) -> [T]? {
        var results = [T]()
        
        for j in json {
            if let result = T.decode(j) {
                results.append(result)
            }
        }
        
        return results
    }
}
