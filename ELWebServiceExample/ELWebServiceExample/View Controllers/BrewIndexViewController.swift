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
    fileprivate(set) var brewClient = BrewClient()
    fileprivate var brews = [Brew]() {
        didSet {
            tableView?.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchBrews()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Tasty Brews"
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: "BrewCell")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add Brew", style: UIBarButtonItemStyle.plain, target: self, action: #selector(BrewIndexViewController.addBrewTapped))
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
            .responseError { error in
                print("I AM ERROR = \(error)")
            }
            .resume()
    }
}

// MARK: - Table View

extension BrewIndexViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return brews.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BrewCell", for: indexPath)
        
        let brew = brews[(indexPath as NSIndexPath).row]
        cell.textLabel?.text = brew.name
        
        return cell
    }
}

extension BrewIndexViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let brew = brews[(indexPath as NSIndexPath).row]
        brewTapped(brew)
    }
}

// MARK: - Actions

extension BrewIndexViewController {
    
    func addBrewTapped() {
        let brewAddViewController = BrewAddViewController(brewClient: brewClient)
        let navigationController = UINavigationController(rootViewController: brewAddViewController)
        present(navigationController, animated: true, completion: nil)
    }
    
    func brewTapped(_ brew: Brew) {
        let brewDetailViewController = BrewDetailViewController(brew: brew)
        navigationController?.pushViewController(brewDetailViewController, animated: true)
    }
}
