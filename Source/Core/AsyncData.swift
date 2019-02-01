//
//  AsyncData.swift
//  ELWebService
//
//  Created by Alex Johnson on 1/31/19.
//  Copyright © 2019 WalmartLabs. All rights reserved.
//

import Foundation

/// The result of an asynchronous operation that provides data.
enum AsyncDataResult {
    case success(Data)
    case failure(Error)
}

/// A closure that asynchronously provides data.
typealias AsyncDataProvider = (_ callback: @escaping (AsyncDataResult) -> Void) -> Void
