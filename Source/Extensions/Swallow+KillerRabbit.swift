//
//  Swallow+KillerRabbit.swift
//  Swallow
//
//  Created by Angelo Di Paolo on 4/7/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

#if NOFRAMEWORKS
#else
import THGWebService
import THGDispatch
#endif

extension ServiceTask {
    
    public func responseOnDispatchQueue(dispatchQueue: DispatchQueue, handler: SuccessHandler) -> Self {
        return response(dispatchQueue.dispatchQueue(), handler: handler)
    }
}
