//
//  StoreService.swift
//  Swallow
//
//  Created by Angelo Di Paolo on 2/24/15.
//  Copyright (c) 2015 SetDirection. All rights reserved.
//

import Foundation
import THGWebService

// MARK - Web Service Configuration

extension WebService {
    
    static let baseURL = "http://somehapi.herokuapp.com/"
    
    static func StoresService() -> WebService {
        return WebService(baseURLString: baseURL)
    }
}

// MARK - Request Configuration

extension WebService {
    
    public func fetchStores(zipCode aZipCode: String) -> ServiceTask {
        return GET("/stores", parameters: ["zip" : aZipCode])
    }
}

// MARK - Response Processing

extension ServiceTask {
    
    public typealias StoreServiceSuccess = ([StoreModel]?) -> Void
    public typealias StoreServiceError = (NSError?) -> Void
    
    func responseStores(handler: StoreServiceSuccess) -> Self {
        return responseJSON { json in
            
            if let models = self.parseJSONAsStoreModels(json) {
                handler(models)
            } else {
                self.result = Result(data: nil, response: nil, error: self.modelParseError())
            }
        }
    }
    
    private func parseJSONAsStoreModels(json: AnyObject?) -> [StoreModel]? {
        if let dictionary = json as? NSDictionary {
            if let array = dictionary["stores"] as? NSArray {
                var models = [StoreModel]()

                for item in array {
                    let model = StoreModel(dictionary: item as! NSDictionary)
                    models.append(model)
                }
                
                return models
            }
        }
        
        return nil
    }
    
    private func modelParseError() -> NSError {
        return NSError(domain: "com.THGWebService.storeservice", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse model JSON"])
    }
}

// MARK: - Model

public struct StoreModel {
    
    struct JSONKeys {
        static let name = "name"
        static let phoneNumber = "phoneNumber"
    }
    
    var phoneNumber: String?
    var address: String?
    var storeID: String?
    var name: String?
    
    init(dictionary: NSDictionary) {
        self.name = dictionary[JSONKeys.name] as? String
        self.phoneNumber = dictionary[JSONKeys.phoneNumber] as? String
    }
}
