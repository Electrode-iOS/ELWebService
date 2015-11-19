//
//  ServiceTask+Brew.swift
//  SwallowExample
//
//  Created by Angelo Di Paolo on 9/30/15.
//  Copyright © 2015 TheHolyGrail. All rights reserved.
//

import Foundation
import THGWebService

extension ServiceTask {
    
    func responseAsBrews(handler: ([Brew]) -> Void) -> Self {
        return
            responseJSON { json in
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
