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

class SearchPostsController: UIViewController, UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating{
    
    @IBOutlet weak var tableView: UITableView!
    var imageArray = [Image]()
    var filteredImages = [Image]()
    var shouldShowSearchResults = false
    var searchController : UISearchController!
    var imageObj = Image()
    var uiImageArray = [UIImage]()
    var chosenImage = UIImage()
    var user = User()
    
    var uiImageDictArray : [[String: UIImage]] = []
    
    override func viewDidLoad(){
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = UIColor.white
        tableView.delegate = self
        tableView.dataSource = self
        configureSearchController()
        navigationItem.backBarButtonItem?.tintColor = UIColor.white
        navigationItem.title = "Search Posts"
        createUIImageDict()
        
        
    }
    
    func createUIImageDict(){
        for i in 1...imageArray.count - 1{
           var uiImageDict : [String: UIImage] = [:]
           uiImageDict[imageArray[i].imageID] = uiImageArray[i]
            uiImageDictArray.append(uiImageDict)
            
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        shouldShowSearchResults = true
        tableView.reloadData()
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        shouldShowSearchResults = false
        tableView.reloadData()
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if !shouldShowSearchResults{
            shouldShowSearchResults = true
            tableView.reloadData()
        }
        
        searchController.searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if !shouldShowSearchResults{
            shouldShowSearchResults = true
            tableView.reloadData()
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchString = searchController.searchBar.text
        
        // Filter the data array and get only those countries that match the search text.
        filteredImages = imageArray.filter({ (image) -> Bool in
            let imagePlace: NSString = image.placeTitle as NSString
            
            return imagePlace.lowercased.contains((searchString?.lowercased())!)
        })
        
        // Reload the tableview.
        tableView.reloadData()
    }
    
    func configureSearchController(){
        searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        tableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.sizeToFit()
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if shouldShowSearchResults{
            return filteredImages.count
        }else{
            return imageArray.count
        }
        
        
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:ResultsTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "resultsCell")! as! ResultsTableViewCell
        cell.imgView.layer.cornerRadius = 5
        if shouldShowSearchResults{
            cell.placeTitleLabel.text = filteredImages[indexPath.row].placeTitle
            cell.userNameLabel.text = filteredImages[indexPath.row].ownerName
            imageObj = filteredImages[indexPath.row]
            for imgDict in uiImageDictArray{
                if imgDict[filteredImages[indexPath.row].imageID] != nil{
                    cell.imgView.image = imgDict[filteredImages[indexPath.row].imageID]!
                }
            }

        }else{
            
            cell.imgView.image = uiImageArray[indexPath.row]
            cell.placeTitleLabel.text = imageArray[indexPath.row].placeTitle
            cell.userNameLabel.text = imageArray[indexPath.row].ownerName
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
         searchController.searchBar.resignFirstResponder()
       
        if shouldShowSearchResults{
            imageObj = filteredImages[indexPath.row]
            for imgDict in uiImageDictArray{
                if imgDict[filteredImages[indexPath.row].imageID] != nil{
                    chosenImage = imgDict[filteredImages[indexPath.row].imageID]!
                }
            }
        }else{
            imageObj = imageArray[indexPath.row]
            chosenImage = uiImageArray[indexPath.row]
        }
         searchController.isActive = false
        shouldShowSearchResults = false
        self.performSegue(withIdentifier: "viewPostFromSearch", sender: nil)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print(segue.identifier)
        if segue.identifier == "viewPostFromSearch" {
            let image = Image()
            
            if let destinationVC = segue.destination as? viewPostController{
                
                destinationVC.imageTapped = self.chosenImage
                destinationVC.imageObj = self.imageObj
                destinationVC.imageID = (self.imageObj?.imageID)!
                destinationVC.user = self.user
            }
        }
    }
    

}

class ResultsTableViewCell: UITableViewCell{

    @IBOutlet weak var userNameLabel: UILabel!

    @IBOutlet weak var placeTitleLabel: UILabel!
    
    @IBOutlet weak var imgView: UIImageView!
}
