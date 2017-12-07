//
//  ServiceTask+JSON.swift
//  ELWebServiceExample
//
//  Created by Angelo Di Paolo on 9/30/15.
//  Copyright © 2015 WalmartLabs. All rights reserved.
//

import Foundation
import ELWebService

enum SessionTaskDecodeError: Error {
    case failedToDecodeJSONArray
    case failedToDecodeJSONObject
}
