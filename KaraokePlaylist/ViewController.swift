//
//  ViewController.swift
//  KaraokePlaylist
//
//  Created by Данияр on 02.07.17.
//  Copyright © 2017 Данияр. All rights reserved.
//

import UIKit
import SQLite

class ViewController: UITableViewController {
    
    var detailViewController: DetailViewController? = nil
    var karaokes = [Karaoke]()
    let searchController = UISearchController(searchResultsController: nil)
    
    struct defaultsKeys {
        static let pswd = "password"
    }

    let path = NSSearchPathForDirectoriesInDomains(
        .documentDirectory, .userDomainMask, true
        ).first!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        
        // Setup the Scope Bar
//        searchController.searchBar.scopeButtonTitles = ["All", "Chocolate", "Hard", "Other"]
        tableView.tableHeaderView = searchController.searchBar
                        
        if let splitViewController = splitViewController {
            let controllers = splitViewController.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        
        let defaults = UserDefaults.standard
        if (defaults.string(forKey: defaultsKeys.pswd) == nil) {
            let pass:String = "12345"
            defaults.set(pass, forKey: defaultsKeys.pswd)
        }
        
    }

    override func viewWillAppear(_ animated: Bool) {
//        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
        
        // Add a background view to the table view
        let backgroundImage = UIImage(named: "bg_karaoke.png")
        let imageView = UIImageView(image: backgroundImage)
        self.tableView.backgroundView = imageView
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table View
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return karaokes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let karaoke: Karaoke
        karaoke = karaokes[indexPath.row]
        cell.textLabel!.text = karaoke.comp_id! + " " + karaoke.quality!
        cell.detailTextLabel!.text = karaoke.song! + " " + karaoke.artist!
        return cell
    }
    
    
    // MARK: FILTERING
    func filterContentForSearchText(_ searchText: String) {
        
        let db = try! Connection("\(path)/db.sqlite3")
        let karaoke = Table("karaoke")
        
        let comp_id = Expression<String>("comp_id")
        let artist = Expression<String>("artist")
        let song = Expression<String>("song")
        let quality = Expression<String>("quality")
        
        karaokes = [Karaoke]()
        
        var myFilter = Expression<Bool?>(value: true)
        
        if searchText.characters.count < 2 {
            myFilter = Expression<Bool?>(value: false)
        }
        
        let arr = searchText.components(separatedBy: " ")
        
        for text in arr {
            if text != "" {
                myFilter = myFilter && (
                    comp_id.like("%\(text.uppercased())%")
                    || song.like("%\(text.uppercased())%")
                    || artist.like("%\(text.uppercased())%")
                    || quality.like("%\(text.uppercased())%")
                )
            }
        }
        
        let query = karaoke.select(karaoke[*])
            .filter(myFilter)
        
        for kar in try! db.prepare(query) {
            karaokes.append(Karaoke(comp_id : kar[comp_id], song: kar[song], artist: kar[artist], quality: kar[quality]))
        }
        
        tableView.reloadData()
    }
    
    
    // MARK: - Segues
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        if identifier == "options" {
            
            
            let newWordPrompt = UIAlertController(title: "Администрирование", message: "Введите пароль!", preferredStyle: UIAlertControllerStyle.alert)
            newWordPrompt.addTextField(configurationHandler: { (textField: UITextField!) in
                textField.placeholder = "Введите пароль"
                })
            newWordPrompt.addAction(UIAlertAction(title: "Отмена", style: UIAlertActionStyle.default, handler: nil))
            newWordPrompt.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {
                alert -> Void in
                
                let passField = newWordPrompt.textFields![0] as UITextField
                
                let defaults = UserDefaults.standard
                if let password = defaults.string(forKey: defaultsKeys.pswd) {
                    if passField.text == password {
                        self.performSegue(withIdentifier: "options", sender: self)
                    }
                }

            
            }))
            present(newWordPrompt, animated: true, completion: nil)
            
            return false
        }
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "options" {
            
            let controller = segue.destination as!  OptionsController
            controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
        }
        
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let karaoke: Karaoke = karaokes[indexPath.row]
                let navcontroller = segue.destination as! UINavigationController
                let controller = navcontroller.topViewController as! DetailViewController
                controller.detailKaraoke = karaoke
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

}

extension ViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!)
        
        searchBar.setValue("Отмена", forKey:"_cancelButtonText")
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        filterContentForSearchText(searchBar.text!)
    }
}

extension ViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

