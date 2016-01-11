//
//  PickLocation.swift
//  LiveNite
//
//  Created by Kevin on 1/3/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer
import MobileCoreServices
import AVFoundation
import CoreData
import CoreLocation
import GoogleMaps

class PickLocationController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout, UITableViewDelegate, CLLocationManagerDelegate, UITableViewDataSource{
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet weak var selectedImageView: UIImageView!
    
    var vc = ViewController()
    var saved = false
    var locations = 1
    var selectedImage = UIImage()
    var listOfPlaces : [String] = []
    //variable for accessing location
    var locationManager = CLLocationManager()
    var userLocation = CLLocationCoordinate2D()
    var locationUpdated = false
    var complete = false
    let captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    var captureDevice : AVCaptureDevice?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.view.hidden = true
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "Background_Gradient")!)
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        tableView.dataSource = self
        tableView.delegate = self
        if #available(iOS 8.0, *) {
            locationManager.requestWhenInUseAuthorization()
        } else {
            // Fallback on earlier versions
        }
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        
        
        
    }
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations[0].coordinate
        print("\(userLocation.latitude) Degrees Latitude, \(userLocation.longitude) Degrees Longitude")
        locationUpdated = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print("view appeared")
        //location settings
        //needs better error checking

        
        if (complete == false){
            takeAndSave()
        }else if (complete == true && saved == false){
        
            dismissViewControllerAnimated(true, completion: nil)

            

        }else{
            fetchNearbyPlaces(userLocation)
            tableView.reloadData()
        }

    }
    

    

    func takeAndSave(){
        
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            
            print("captureVideoPressed and camera available.")
            
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            imagePicker.sourceType = .Camera;
            //imagePicker.mediaTypes = [kUTTypeMovie!]
            imagePicker.allowsEditing = false
            
            imagePicker.showsCameraControls = true

            self.presentViewController(imagePicker, animated: true, completion: nil)
            complete = true
            
        }
            
        else {
            print("Camera not available.")
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info:[String : AnyObject]) {
        
        self.selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        selectedImageView.image = self.selectedImage
        


        
        dismissViewControllerAnimated(true, completion: nil)
        saved = true
        locationManager.stopUpdatingLocation()
        
        
        
    }
    
    func getImageId()-> Int{
        var currentID = 1
        let fetchRequest = NSFetchRequest(entityName: "CurrentID")
        let locations = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        if let locations = locations{
            for loc in locations{
                let idData : AnyObject? = loc.valueForKey("id")
                if (idData == nil){
                    currentID = 1
                }else{
                    currentID = (idData as? Int)!
                }
                
                
                
            }}
        if let newId = NSEntityDescription.insertNewObjectForEntityForName("CurrentID", inManagedObjectContext:context) as? NSManagedObject{
            currentID = currentID + 1
            newId.setValue(currentID, forKey: "id")
            do {
                try context.save()
            } catch _ {
            }
        }
        return currentID
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func retrieveListOfPlaces(listOfPlaces: [String]){
        self.listOfPlaces = listOfPlaces
        
        tableView.reloadData()
        self.view.hidden = false
       
    }
    
    
    func fetchNearbyPlaces(coordinate: CLLocationCoordinate2D) {
        let searchRadius:Double = 3000
        var list : [String] = []
        let searchedTypes = ["bar","club","restaurant","establishment"]
        let dataProvider = GoogleDataProvider()
        dataProvider.fetchPlacesNearCoordinate(coordinate,radius: searchRadius,types: searchedTypes) { places in
            for place: GooglePlace in places {
                list.append(place.name as String)
               
                if (list.count == places.count){
                     self.retrieveListOfPlaces(list)
                }
                
            }
        }
    }
    func numberOfSectionsinTableView(tableView: UITableView) -> Int{
        return 1
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int)-> Int{
        return self.listOfPlaces.count
    }
    
    
    func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath: NSIndexPath)-> UITableViewCell{
        
        let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell
        tableView.backgroundColor = UIColor.clearColor()
        tableView.opaque = false
        cell.backgroundColor = UIColor.clearColor()
        cell.opaque = false
        if (self.listOfPlaces.count != 0){
            cell.textLabel?.text = self.listOfPlaces[indexPath.row]
        
            cell.textLabel?.textColor = UIColor.whiteColor()
        }
        return cell
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        var cell : UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        var cellText : String = (cell.textLabel?.text)!
        if let newVideo = NSEntityDescription.insertNewObjectForEntityForName("Entity", inManagedObjectContext:context) as? NSManagedObject{
            let tempImage = self.selectedImage
            let dataImage:NSData = UIImageJPEGRepresentation(tempImage, 0.0)!
            newVideo.setValue(dataImage, forKey: "videoData")
            var date = NSDate()
            var calendar = NSCalendar.currentCalendar()
            var components = calendar.components([.Hour, .Minute], fromDate: date)
            var hourOfDate = components.hour
            newVideo.setValue(hourOfDate, forKey: "time")
            var setImageTitle : String = cellText
            var setUpVotes : Int = 0
            var setId : Int = getImageId()
            print(setId, terminator: "")
            newVideo.setValue(setId, forKey: "id")
            newVideo.setValue(setUpVotes, forKey: "upvotes")
            newVideo.setValue(setImageTitle, forKey: "title")
            do {
                try context.save()
            } catch _ {
            }
            print("saved successfully", terminator: "")
            dismissViewControllerAnimated(true, completion: nil)
            
            
            
        }
    }
    
}