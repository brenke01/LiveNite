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


class PickLocationController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout, UITableViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate, UISearchDisplayDelegate{
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet weak var textField: UITextView!
    @IBOutlet weak var pickLocNav: UINavigationBar!
    @IBOutlet weak var stopButton: UINavigationBar!
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    var vc = ViewController()
    var saved = false
    var user = User()
    var locations = 1
    var selectedImage = UIImage()
    var searchBar: UISearchBar?
    var tableDataSource: GMSAutocompleteTableDataSource?
    var srchDisplayController: UISearchDisplayController?
    var placePicker : GMSPlacePicker!
    var googleMapView: GMSMapView!
    var listOfPlaces : [String] = []
    //variable for accessing location
    var locationManager = CLLocationManager()
    var userLocation = CLLocationCoordinate2D()
    var locationUpdated = false
    var complete = false
    //var textField = UITextField()
    let captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    var captureDevice : AVCaptureDevice?
    var locationDictionary = [String: CLLocationCoordinate2D]()
    var currentUserName : String = ""
    var chosenLocation = ""
    var userName = ""
    var chosenLatitude :Double = 0.0
    var chosenLongitude: Double = 0.0
    var submitButton = UIButton()
    var chosenLongFromMap = 0.0
    var chosenLatFromMap = 0.0
    var mapPickedLocation = false
    var userID = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        

        searchBar = UISearchBar(frame: CGRectMake(0, 10, 250.0, 44.0))
        self.view.addSubview(textField)
       // tableDataSource = GMSAutocompleteTableDataSource()
        //tableDataSource?.delegate = self
        
        srchDisplayController = UISearchDisplayController(searchBar: searchBar!, contentsController: self)
        srchDisplayController?.searchResultsDataSource = tableDataSource
        srchDisplayController?.searchResultsDelegate = tableDataSource
        //segmentedControl.tintColor = UIColor.whiteColor()
        //segmentedControl.backgroundColor = UIColor.darkGrayColor()
        
        let navBarBGImage = UIImage(named: "Navigation_Bar_Gold")
        pickLocNav.setBackgroundImage(navBarBGImage, forBarMetrics: .Default)
        pickLocNav.topItem!.title = "Pick Location"
       
        self.view.hidden = true
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "Background_Gradient")!)
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //tableView.dataSource = self
        //tableView.delegate = self
        if #available(iOS 8.0, *) {
            locationManager.requestWhenInUseAuthorization()
        } else {
            // Fallback on earlier versions
        }
        //self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
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
     
            tableView.hidden = false
            pickLocNav.topItem!.title = "Pick Location"
            self.submitButton.removeFromSuperview()
            self.textField.removeFromSuperview()
            
        
    }
    
    func searchPlaces() {
        self.googleMapView = GMSMapView(frame: self.view.frame)
        self.googleMapView.backgroundColor = UIColor.darkGrayColor()
        googleMapView.tintColor = UIColor.darkGrayColor()

        //self.view.addSubview(googleMapView)
        let center = CLLocationCoordinate2DMake(userLocation.latitude, userLocation.longitude)
        let northEast = CLLocationCoordinate2DMake(center.latitude + 0.001, center.longitude + 0.001)
        let southWest = CLLocationCoordinate2DMake(center.latitude - 0.001, center.longitude - 0.001)
        let viewport = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        let coordinates = self.userLocation
        let marker = GMSMarker(position: coordinates)
        marker.map = self.googleMapView
        self.googleMapView.animateToLocation(coordinates)
        let config = GMSPlacePickerConfig(viewport: viewport)
        placePicker = GMSPlacePicker(config: config)

        self.placePicker?.pickPlaceWithCallback({ (place: GMSPlace?, error: NSError?) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }
            
            if let place = place {
                print("Place name \(place.name)")
                print("Place address \(place.formattedAddress)")
                print("Place attributions \(place.attributions)")
                print(place.coordinate)
                self.chosenLatFromMap = place.coordinate.latitude
                self.chosenLongFromMap = place.coordinate.longitude
                let loc = CLLocation(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                var placeLoc = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
                if (loc.distanceFromLocation(placeLoc) > 3000.0){
                    let alertController = UIAlertController(title: "Error", message: "The selected location is too far away from your location", preferredStyle: UIAlertControllerStyle.Alert)
                    alertController.addAction(UIAlertAction(title:"Dismiss", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alertController, animated: true, completion: nil)
                }else{
                    self.chosenLocation = place.name
                    self.mapPickedLocation = true
                    self.chosenLatitude = place.coordinate.latitude
                    self.chosenLongitude = place.coordinate.longitude
                    self.loadCaptionView()
                }
                
            } else {
                print("No place selected")
            }
        })
    
    
    }
    
    func didUpdateAutocompletePredictionsForTableDataSource(tableDataSource: GMSAutocompleteTableDataSource) {
        // Turn the network activity indicator off.
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        // Reload table data.
        srchDisplayController?.searchResultsTableView.reloadData()
    }
    
    func didRequestAutocompletePredictionsForTableDataSource(tableDataSource: GMSAutocompleteTableDataSource) {
        // Turn the network activity indicator on.
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        // Reload table data.
        srchDisplayController?.searchResultsTableView.reloadData()
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
            var searchedTypes = ["bar"]
            //fetchNearbyPlaces(userLocation, searchedTypes: searchedTypes)
            //tableView.reloadData()
            
            searchPlaces()
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
        //selectedImageView.image = self.selectedImage
        dismissViewControllerAnimated(true, completion: nil)
        saved = true
        locationManager.stopUpdatingLocation()
        
        
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    



    func saveImageInfo(sender: UIButton!){
        let tempImage = self.selectedImage
        let dataImage:NSData = UIImageJPEGRepresentation(tempImage, 0.0)!
        let date = NSDate()
        let setImageTitle : String = self.chosenLocation
        let setId : String = NSUUID().UUIDString
        var imageURL = ""
        let myImage : Image = Image()
        AWSService().saveImageToBucket(dataImage, id: setId, placeName: setImageTitle, completion: {(result)->Void in
             dispatch_async(dispatch_get_main_queue(), {
            imageURL = result
            myImage.imageID = setId
            myImage.placeTitle = setImageTitle
            myImage.caption = self.textField.text
            myImage.eventID = NSUUID().UUIDString
            myImage.picTakenLat = self.userLocation.latitude
            myImage.picTakenLong = self.userLocation.longitude
            myImage.owner = self.user.userName
            myImage.userID = self.user.userID
            myImage.hotColdScore = 0
            myImage.placeLat = self.chosenLatFromMap
            myImage.placeLong = self.chosenLongFromMap
            myImage.url = imageURL
            
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            myImage.timePosted = formatter.stringFromDate(date)
            myImage.totalScore = 0
            var geo :Geohash = Geohash()
           let l =  CLLocationCoordinate2DMake((self.locationManager.location?.coordinate.latitude)!, (self.locationManager.location?.coordinate.longitude)!)
            let s = l.geohash(10)
            let index = s.endIndex.advancedBy(-7)
            myImage.geohash = s.substringToIndex(index)
            AWSService().save(myImage)
            })
            
        })
        

        
        
        print("saved successfully", terminator: "")
        dismissViewControllerAnimated(true, completion: nil)
        tabBarController?.selectedIndex = 0
    }

    func loadCaptionView(){
        self.view.hidden = false
        pickLocNav.topItem!.title = "Add Caption"
        //tableView.hidden = true
        //textField = UITextField(frame: CGRect(x: self.view.frame.origin.x, y: self.view.frame.origin.y, width: self.view.frame.width, height: self.view.frame.height * 0.5))
        textField.becomeFirstResponder()
        textField.textColor = UIColor.blackColor()
        textField.backgroundColor = UIColor.whiteColor()
        textField.autocorrectionType = UITextAutocorrectionType.Default
        textField.keyboardType = UIKeyboardType.Default
        textField.font = UIFont (name: "HelveticaNeue", size: 20)
        /*UITextField.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            
                self.textField.frame.origin.y =  (self.textField.frame.origin.y - self.view.frame.height - 5) + self.pickLocNav.frame.height
            }, completion: nil)*/
        
        
        submitButton = UIButton(frame: CGRect(x: self.view.frame.width * 0.50, y: self.view.frame.height * 0.50,width: self.view.frame.width * 0.5 - 10, height: 40 ))
        submitButton.backgroundColor = UIColor(red: 0.9294, green: 0.8667, blue: 0, alpha: 1.0)
        submitButton.setTitle("Post", forState: .Normal)
        submitButton.layer.cornerRadius = 5
        submitButton.enabled = true
        submitButton.layer.opacity = 1.0
        submitButton.setTitleColor(UIColor.grayColor(), forState: UIControlState.Normal)
        submitButton.titleLabel!.font = UIFont(name:
            "HelveticaNeue-Medium", size: 18)
        submitButton.addTarget(self, action: "saveImageInfo:", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(submitButton)
        
        
        
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if (textField.text?.isEmpty == false){
            submitButton.enabled = true;
            submitButton.layer.opacity = 1.0
            submitButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        }
    }
    
}

extension PickLocationController: GMSAutocompleteTableDataSourceDelegate {
    func tableDataSource(tableDataSource: GMSAutocompleteTableDataSource, didAutocompleteWithPlace place: GMSPlace) {
        srchDisplayController?.active = false
        // Do something with the selected place.
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress)")
        print("Place attributions: \(place.attributions)")
    }
    
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String?) -> Bool {
        tableDataSource?.sourceTextHasChanged(searchString)
        return false
    }
    
    func tableDataSource(tableDataSource: GMSAutocompleteTableDataSource, didFailAutocompleteWithError error: NSError) {
        // TODO: Handle the error.
        print("Error: \(error.description)")
    }
    
    func tableDataSource(tableDataSource: GMSAutocompleteTableDataSource, didSelectPrediction prediction: GMSAutocompletePrediction) -> Bool {
        return true
    }
}