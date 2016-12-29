//
//  SearchPostsController.swift
//  LiveNite
//
//  Created by Kevin  on 12/28/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//

import Foundation
import Foundation
import UIKit
import MediaPlayer
import MobileCoreServices
import AVFoundation
import CoreData
import CoreLocation
import GoogleMaps
import AWSDynamoDB

class SearchPostsController: UIViewController, UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var tableView: UITableView!
    var imageArray = [Image]()
    var imageSearchResults = [Image]()
    
    override func viewDidLoad(){
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return self.imageArray.count
    }
    func filterContentForSearchText(searchText: String){
        if self.imageArray == [] {
            self.imageSearchResults = []
            return
        }
        self.imageSearchResults = self.imageArray.filter({( img: Image) -> Bool in
            // to start, let's just search by name
            return (img.placeTitle.lowercased().range(of: searchText.lowercased()) != nil)
        })
    }
    
    func searchDisplayController(controller: UISearchDisplayController!, shouldReloadTableForSearchString searchString: String!) -> Bool {
        self.filterContentForSearchText(searchText: searchString)
        return true
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:ResultsTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "resultsCell")! as! ResultsTableViewCell
        
        var imageSearchArray = [Image]()
        if tableView == self.searchDisplayController!.searchResultsTableView {
            imageSearchArray = self.imageSearchResults
        } else {
            imageSearchArray = self.imageArray
        }
        
        if imageSearchArray != [] && imageSearchArray.count >= indexPath.row
        {
            let image = imageSearchArray[indexPath.row]

            cell.placeTitleLabel.text = image.placeTitle
            cell.userNameLabel.text = image.owner
            if tableView != self.searchDisplayController!.searchResultsTableView {

            }
        }
        
        return cell
    }
    


}

class ResultsTableViewCell: UITableViewCell{

    @IBOutlet weak var userNameLabel: UILabel!

    @IBOutlet weak var placeTitleLabel: UILabel!
    
}
