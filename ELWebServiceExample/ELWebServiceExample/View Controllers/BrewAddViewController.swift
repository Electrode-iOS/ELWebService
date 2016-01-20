//
//  BrewAddViewController.swift
//  SwallowExample
//
//  Created by Angelo Di Paolo on 9/30/15.
//  Copyright © 2015 TheHolyGrail. All rights reserved.
//

import UIKit
import ELWebService

class BrewAddViewController: UIViewController {
    
    @IBOutlet weak var brewNameField: UITextField?
    @IBOutlet weak var brewStyleField: UITextField?
    private(set) var brewClient: BrewClient
    private var brew: Brew? {
        guard let name = brewNameField?.text else {return nil}
        guard let style = brewStyleField?.text else {return nil}
        
        return Brew(name: name, style: style)
    }
    
    required init(brewClient: BrewClient) {
        self.brewClient = brewClient
        super.init(nibName: "BrewAddViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Add Brew"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: "cancelTapped")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.Plain, target: self, action: "saveTapped")
    }
}

extension BrewAddViewController {
    
    func cancelTapped() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func saveTapped() {
        guard let brew = brew else { return }
        
        brewClient
            .insertBrew(brew)
            .updateUI { [weak self] value in
                self?.dismissViewControllerAnimated(true, completion: nil)
            }
            .updateErrorUI { error in
                print("I AM ERROR = \(error)")
            }
            .resume()
    }
}

// MARK: - UITextFieldDelegate

extension BrewAddViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
