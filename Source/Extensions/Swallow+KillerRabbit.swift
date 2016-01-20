//
//  Swallow+KillerRabbit.swift
//  Swallow
//
//  Created by Angelo Di Paolo on 4/7/15.
//  Copyright (c) 2015 WalmartLabs. All rights reserved.
//

import THGWebService
import THGDispatch

extension ServiceTask {
    
    public func responseOnDispatchQueue(dispatchQueue: DispatchQueue, handler: SuccessHandler) -> Self {
        return response(dispatchQueue.dispatchQueue(), handler: handler)
    }
}
