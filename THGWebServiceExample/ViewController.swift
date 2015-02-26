//
//  ViewController.swift
//  THGWebServiceExample
//
//  Created by Angelo Di Paolo on 2/25/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchStores()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func fetchStores() {
        
        // fetch some store locator results from service API
        
        WebService.StoresService()
            .fetchStores(zipCode: "15217")
            .responseStoreModels { stores in
                println("success. the first store phone number is \(stores?.first?.phoneNumber)")
            }
            .responseError { error in
                println("fetch error \(error)")
            }
        
    }

}

