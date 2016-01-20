//
//  ServiceTask+JSON.swift
//  ELWebServiceExample
//
//  Created by Angelo Di Paolo on 9/30/15.
//  Copyright © 2015 WalmartLabs. All rights reserved.
//

import Foundation
import ELWebService

enum ServiceTaskDecodeError: ErrorType {
    case FailedToDecodeJSONArray
    case FailedToDecodeJSONObject
}

extension ServiceTask {
    
    public func jsonObject(json: AnyObject, forKey key: String?) -> AnyObject? {
        if let key = key {
            return json[key]
        } else {
            return json
        }
        
    }
}
