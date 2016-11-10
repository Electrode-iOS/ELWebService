//
//  ServiceTask+ResponseInjection.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 2/3/16.
//  Copyright © 2016 WalmartLabs. All rights reserved.
//

import Foundation
@testable import ELWebService

extension ServiceTask {
    // expose internal handleResponse method to obj-c tests via injectResponse()
    @objc public func injectResponse(_ response: URLResponse?, data: Data?, error: NSError?) {
        handleResponse(response, data: data, error: error)
    }
}

