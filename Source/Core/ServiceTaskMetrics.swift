//
//  ServiceTaskMetrics.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 8/4/17.
//  Copyright © 2017 WalmartLabs. All rights reserved.
//

import Foundation

/// Encapsulates performance metrics collected during the execution of a service task.
public struct ServiceTaskMetrics {
    /// The time immediately after the` URLSessionDataTask`'s `resume` method is called.
    public internal(set) var fetchStartDate: Date?
    
    /// The time immediately after the `URLSessionDataTask`'s completion handler is called.
    public internal(set) var responseEndDate: Date?
    
    /// The time interval between `fetchStartDate` and `responseEndDate`
    public var responseTime: TimeInterval? {
        guard
            let startDate = fetchStartDate,
            let endDate = responseEndDate else {
                return nil
        }
        return endDate.timeIntervalSince(startDate)
    }
}
