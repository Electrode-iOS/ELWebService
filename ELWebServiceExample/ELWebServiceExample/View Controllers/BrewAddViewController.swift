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
    fileprivate(set) var brewClient: BrewClient
    fileprivate var brew: Brew? {
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
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(BrewAddViewController.cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.plain, target: self, action: #selector(BrewAddViewController.saveTapped))
    }
}

extension BrewAddViewController {
    
    @objc func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func saveTapped() {
        guard let brew = brew else { return }
        
        brewClient
            .save(brew: brew)
            .updateUI { [weak self] value in
                self?.dismiss(animated: true, completion: nil)
            }
            .updateErrorUI { error in
                print("I AM ERROR = \(error)")
            }
            .resume()
    }
}

// MARK: - UITextFieldDelegate

extension BrewAddViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
