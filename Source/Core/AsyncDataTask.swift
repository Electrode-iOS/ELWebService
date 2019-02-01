//
//  AsyncDataTask.swift
//  ELWebService
//
//  Created by Alex Johnson on 1/31/19.
//  Copyright © 2019 WalmartLabs. All rights reserved.
//

import Foundation

/// A `DataTask` implementation that asynchronously materializes data.
class AsyncDataTask: DataTask {
    private enum DataState {
        case ready(AsyncDataProvider)
        case materializing(Date)
        case completed(AsyncDataResult)
    }

    private let completion: (AsyncDataResult) -> Void

    private var dataState: DataState {
        willSet {
            switch (dataState, newValue) {
            case (.ready, .materializing),
                 (.materializing, .completed):
                break
            default:
                fatalError("Illegal state transition from \(dataState) to \(newValue)")
            }
        }
    }

    private(set) var state: URLSessionTask.State = .suspended

    init(_ provideData: @escaping AsyncDataProvider, completion: @escaping (AsyncDataResult) -> Void) {
        dataState = .ready(provideData)
        self.completion = completion
    }

    func suspend() {
        guard state == .running else {
            return
        }

        state = .suspended
    }

    func resume() {
        guard state == .suspended else {
            return
        }

        state = .running

        switch dataState {
        case .ready(let provideData):
            dataState = .materializing(Date())

            provideData { [weak self] result in
                runOnMainThread {
                    self?.dataState = .completed(result)
                    self?.complete(result)
                }
            }
        case .materializing:
            break
        case .completed(let result):
            complete(result)
        }
    }

    func cancel() {
        guard state == .suspended || state == .running else {
            return
        }

        state = .canceling
        complete(.failure(NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil)))
    }

    private func complete(_ result: AsyncDataResult) {
        guard state == .running || state == .canceling else {
            return
        }

        state = .completed
        completion(result)
    }
}

/// Executes the block if this is the main thread. Dispatches the block to the main queue otherwise.
private func runOnMainThread(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async(execute: block)
    }
}
