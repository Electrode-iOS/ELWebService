//
//  BrewIndexViewController.swift
//  SwallowExample
//
//  Created by Angelo Di Paolo on 9/30/15.
//  Copyright © 2015 TheHolyGrail. All rights reserved.
//

import UIKit

class BrewIndexViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView?
    private(set) var brewClient = BrewClient()
    private var brews = [Brew]() {
        didSet {
            tableView?.reloadData()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchBrews()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Tasty Brews"
        tableView?.registerClass(UITableViewCell.self, forCellReuseIdentifier: "BrewCell")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add Brew", style: UIBarButtonItemStyle.Plain, target: self, action: "addBrewTapped")
    }
}

// MARK: - Fetching Data

extension BrewIndexViewController {
    
    func fetchBrews() {
        brewClient
            .fetchAllBrews()
            .responseAsBrews { [weak self] brews in
                self?.brews = brews
            }
            .responseError {error in
                print("I AM ERROR = \(error)")
            }
            .resume()
    }
}

// MARK: - Table View

extension BrewIndexViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return brews.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BrewCell", forIndexPath: indexPath)
        
        let brew = brews[indexPath.row]
        cell.textLabel?.text = brew.name
        
        return cell
    }
}

extension BrewIndexViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        let brew = brews[indexPath.row]
        brewTapped(brew)
    }
}

// MARK: - Actions

extension BrewIndexViewController {
    
    func addBrewTapped() {
        let brewAddViewController = BrewAddViewController(brewClient: brewClient)
        let navigationController = UINavigationController(rootViewController: brewAddViewController)
        presentViewController(navigationController, animated: true, completion: nil)
    }
    
    func brewTapped(brew: Brew) {
        let brewDetailViewController = BrewDetailViewController(brew: brew)
        navigationController?.pushViewController(brewDetailViewController, animated: true)
    }
}
