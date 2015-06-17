//
//  ViewController.swift
//  THGWebServiceExample
//
//  Created by Angelo Di Paolo on 2/25/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import UIKit
import THGWebService

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        WebService.StoresService()
            .fetchStores(zipCode: "15217")
            .responseAsStores { stores in
                print("fetch success. the first store phone number is \(stores?.first?.phoneNumber)")
            }
            .responseError { error in
                print("fetch error \(error)")
        }
    }
}
