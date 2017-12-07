//
//  ServiceTask+Brew.swift
//  ELWebServiceExample
//
//  Created by Angelo Di Paolo on 9/30/15.
//  Copyright © 2015 WalmartLabs. All rights reserved.
//

import Foundation
import ELWebService

extension SessionTask {
    func responseAsBrews(_ handler: @escaping ([Brew]) -> Void) -> Self {
        return
            responseJSON { json, response in
                guard
                let dictionary = json as? [String: Any],
                    let jsonArray = dictionary["brews"] as? [Any],
                    let decodedArray = ModelDecoder<Brew>.decodeArray(jsonArray)
                    else {
                        throw SessionTaskDecodeError.failedToDecodeJSONArray
                }
                
                return .value(decodedArray)
                }
                .updateUI { value in
                    if let brews = value as? [Brew] {
                        handler(brews)
                    }
        }
    }
}
