//
//  BrewDetailViewController.swift
//  SwallowExample
//
//  Created by Angelo Di Paolo on 9/30/15.
//  Copyright © 2015 TheHolyGrail. All rights reserved.
//

import UIKit

class BrewDetailViewController: UIViewController {
    
    @IBOutlet weak var brewStyleLabel: UILabel?
    @IBOutlet weak var breweryNameLabel: UILabel?
    @IBOutlet weak var breweryLocationLabel: UILabel?

    private(set) var brew: Brew

    required init(brew: Brew) {
        self.brew = brew
        super.init(nibName: "BrewDetailViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        renderBrew(brew)
    }
}

extension BrewDetailViewController {
    
    func renderBrew(brew: Brew) {
        title = brew.name
        brewStyleLabel?.text = brew.style
        breweryNameLabel?.text = brew.brewery?.name
        breweryLocationLabel?.text = brew.brewery?.location
    }
}
