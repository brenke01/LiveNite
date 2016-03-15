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

class PickLocationController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout, UITableViewDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITextFieldDelegate{
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet weak var pickLocNav: UINavigationBar!
    @IBOutlet weak var stopButton: UINavigationBar!
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
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
    var captionView = 0
    var textField = UITextField()
    let captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    var captureDevice : AVCaptureDevice?
    var locationDictionary = [String: CLLocationCoordinate2D]()
    var currentUserName : String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        segmentedControl.tintColor = UIColor.whiteColor()
        segmentedControl.backgroundColor = UIColor.darkGrayColor()
        
        let navBarBGImage = UIImage(named: "Navigation_Bar_Gold")
        pickLocNav.setBackgroundImage(navBarBGImage, forBarMetrics: .Default)
        pickLocNav.topItem!.title = "Pick Location"
       
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
        
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id"])
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if ((error) != nil)
            {
                // Process error
                print("Error: \(error)")
                
            }
            else
            {
                self.currentUserName = result.valueForKey("id") as! String
            }
        })
        
        
    }
    @IBAction func exit(sender: AnyObject) {
        if (self.captionView == 1){
            self.captionView = 0
            self.tableView.hidden = false
            self.textField.removeFromSuperview()
        }else{
           self.dismissViewControllerAnimated(false, completion: nil)
        }
        
    }
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations[0].coordinate
        print("\(userLocation.latitude) Degrees Latitude, \(userLocation.longitude) Degrees Longitude")
        locationUpdated = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print(complete)
        print(saved)
        if (complete == false){
            takeAndSave()
        }else if (complete == true && saved == false){
            dismissViewControllerAnimated(true, completion: nil)
        }else{
            var searchedTypes = ["bar", "night_club", "club"]
            fetchNearbyPlaces(userLocation, searchedTypes: searchedTypes)
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
    
    
    
    
    @IBAction func segmentedControlAction(sender: AnyObject) {
        if (segmentedControl.selectedSegmentIndex == 0){
            var subViewOfSegment: UIView = segmentedControl.subviews[0] as UIView
            subViewOfSegment.tintColor = UIColor.whiteColor()
            /*var subViewOfSegment1: UIView = segmentedControl.subviews[1] as UIView
            subViewOfSegment.tintColor = UIColor.darkGrayColor()
            var subViewOfSegment2: UIView = segmentedControl.subviews[2] as UIView
            subViewOfSegment.tintColor = UIColor.darkGrayColor()*/
            getBars()
        }else if (segmentedControl.selectedSegmentIndex == 1){
            var subViewOfSegment: UIView = segmentedControl.subviews[1] as UIView
            subViewOfSegment.tintColor = UIColor.whiteColor()

            getFood()
        }else if (segmentedControl.selectedSegmentIndex == 2){
            var subViewOfSegment: UIView = segmentedControl.subviews[2] as UIView
            subViewOfSegment.tintColor = UIColor.whiteColor()

            getLandmarks()
        }
    }
    func getBars() {

        var searchedTypes = ["bar", "night_club", "club"]
        fetchNearbyPlaces(userLocation, searchedTypes: searchedTypes)
        //tableView.reloadData()
    }
    
    func getFood() {

        var searchedTypes = ["food", "restaurant", "meal_delivery"]
        fetchNearbyPlaces(userLocation, searchedTypes: searchedTypes)
        //tableView.reloadData()
    }
    func getLandmarks() {

        var searchedTypes = ["establishment", "university"]
        fetchNearbyPlaces(userLocation, searchedTypes: searchedTypes)
        //tableView.reloadData()
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
        let images = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        if let images = images{
            for image in images{
                let idData : AnyObject? = image.valueForKey("id")
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
    
    func retrieveListOfPlaces(var listOfPlaces: [String]){
        if (listOfPlaces == []){
            listOfPlaces.append("No nearby places found")
        }
        self.listOfPlaces = listOfPlaces
        tableView.reloadData()
        self.view.hidden = false
       
    }
    
    
    func fetchNearbyPlaces(coordinate: CLLocationCoordinate2D, searchedTypes : [String]) {
        let searchRadius:Double = 1000
        print("Fetch nearby places")
        var list : [String] = []
        let dataProvider = GoogleDataProvider()
        dataProvider.fetchPlacesNearCoordinate(coordinate,radius: searchRadius,types: searchedTypes) { places in
            for place: GooglePlace in places {
                list.append(place.name as String)
                self.locationDictionary.updateValue(place.coordinate, forKey: place.name)
             
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
        let border = CALayer()
        let width = CGFloat(1.0)
        border.borderColor = UIColor.whiteColor().CGColor
        border.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1)
        border.borderWidth = width
        tableView.layer.addSublayer(border)
        
        tableView.opaque = false
        cell.backgroundColor = UIColor.clearColor()
        cell.opaque = false
        if (self.listOfPlaces.count != 0){
            if (indexPath.row == listOfPlaces.count - 1){
                cell.textLabel?.text = ""
                
                cell.textLabel?.textColor = UIColor.whiteColor()
            }else{
                cell.textLabel?.text = self.listOfPlaces[indexPath.row]
                cell.textLabel?.font = UIFont(name: "HelveticaNeue", size: 14)
                cell.textLabel?.textColor = UIColor.whiteColor()
            }
        }
        return cell
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        let cell : UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        let cellText : String = (cell.textLabel?.text)!
        loadCaptionView()
       /* if let newImage = NSEntityDescription.insertNewObjectForEntityForName("Entity", inManagedObjectContext:context) as? NSManagedObject{
            let tempImage = self.selectedImage
            let dataImage:NSData = UIImageJPEGRepresentation(tempImage, 0.0)!
            newImage.setValue(dataImage, forKey: "imageData")
            let date = NSDate()
            newImage.setValue(date, forKey: "time")
            let setImageTitle : String = cellText
            let setUpVotes : Int = 0
            let setId : Int = getImageId()
            print(setId, terminator: "")
            newImage.setValue(setId, forKey: "id")
            newImage.setValue(setUpVotes, forKey: "upvotes")
            newImage.setValue(setImageTitle, forKey: "title")
            newImage.setValue(userLocation.latitude, forKey: "picTakenLatitude")
            newImage.setValue(userLocation.longitude, forKey: "picTakenLongitude")
            newImage.setValue(locationDictionary[setImageTitle]!.latitude, forKey: "titleLatitude")
            newImage.setValue(locationDictionary[setImageTitle]!.longitude, forKey: "titleLongitude")
            newImage.setValue(currentUserName, forKey: "userOP")
            do {
                try context.save()
            } catch _ {
            }
            print("saved successfully", terminator: "")
            dismissViewControllerAnimated(true, completion: nil)
            
            
            
        }*/
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.tableView.hidden = true
        textField.resignFirstResponder()
        return true
    }
    
    func loadCaptionView(){
        self.captionView = 1
        textField = UITextField(frame: CGRect(x: selectedImageView.frame.origin.x, y: self.view.frame.height, width: selectedImageView.frame.width, height: selectedImageView.frame.height + 40))
        textField.delegate = self
        textField.becomeFirstResponder()
        textField.placeholder = "Add caption"
        textField.textColor = UIColor.blackColor()
        textField.borderStyle = UITextBorderStyle.RoundedRect
        textField.autocorrectionType = UITextAutocorrectionType.No
        textField.keyboardType = UIKeyboardType.Default
        textField.returnKeyType = UIReturnKeyType.Done
        textField.clearButtonMode = UITextFieldViewMode.WhileEditing;
        textField.contentVerticalAlignment = UIControlContentVerticalAlignment.Top
        UITextField.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                self.view.addSubview(self.textField)
                self.textField.frame.origin.y =  (self.textField.frame.origin.y - self.view.frame.height - 5) + self.pickLocNav.frame.height
            }, completion: nil)
            
        
        
    }
    
}