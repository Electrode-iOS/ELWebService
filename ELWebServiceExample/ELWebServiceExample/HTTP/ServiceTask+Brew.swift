//
//  ServiceTask+Brew.swift
//  ELWebServiceExample
//
//  Created by Angelo Di Paolo on 9/30/15.
//  Copyright © 2015 WalmartLabs. All rights reserved.
//

import Foundation
import ELWebService

extension ServiceTask {
    
    func responseAsBrews(handler: ([Brew]) -> Void) -> Self {
        return
            responseJSON { json, response in
                if let json = self.jsonObject(json, forKey: "brews"),
                    let jsonArray = json as? [AnyObject],
                    let decodedArray = ModelDecoder<Brew>.decodeArray(jsonArray) {
                        return .Value(decodedArray)
                } else {
                    return .Failure(ServiceTaskDecodeError.FailedToDecodeJSONArray)
                }
            }
            .updateUI { value in
                if let brews = value as? [Brew] {
                    handler(brews)
                }
            }
    }
}
