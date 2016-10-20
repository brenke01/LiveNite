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
        

        searchBar = UISearchBar(frame: CGRect(x: 0, y: 10, width: 250.0, height: 44.0))
        self.view.addSubview(textField)
       // tableDataSource = GMSAutocompleteTableDataSource()
        //tableDataSource?.delegate = self
        
        srchDisplayController = UISearchDisplayController(searchBar: searchBar!, contentsController: self)
        srchDisplayController?.searchResultsDataSource = tableDataSource
        srchDisplayController?.searchResultsDelegate = tableDataSource
        //segmentedControl.tintColor = UIColor.whiteColor()
        //segmentedControl.backgroundColor = UIColor.darkGrayColor()
        
        let navBarBGImage = UIImage(named: "Navigation_Bar_Gold")
        pickLocNav.setBackgroundImage(navBarBGImage, for: .default)
        pickLocNav.topItem!.title = "Pick Location"
       
        self.view.isHidden = true
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
        graphRequest.start(completionHandler: { (connection, result, error) -> Void in
            
            if ((error) != nil)
            {
                // Process error
                print("Error: \(error)")
                
            }
            else
            {
                
                self.currentUserName = (result as AnyObject).object(forKey: "id") as! String
            }
        })
        
        
    }
    @IBAction func exit(_ sender: AnyObject) {
     
            tableView.isHidden = false
            pickLocNav.topItem!.title = "Pick Location"
            self.submitButton.removeFromSuperview()
            self.textField.removeFromSuperview()
            
        
    }
    
    func searchPlaces() {
        self.googleMapView = GMSMapView(frame: self.view.frame)
        self.googleMapView.backgroundColor = UIColor.darkGray
        googleMapView.tintColor = UIColor.darkGray

        //self.view.addSubview(googleMapView)
        let center = CLLocationCoordinate2DMake(userLocation.latitude, userLocation.longitude)
        let northEast = CLLocationCoordinate2DMake(center.latitude + 0.001, center.longitude + 0.001)
        let southWest = CLLocationCoordinate2DMake(center.latitude - 0.001, center.longitude - 0.001)
        let viewport = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        let coordinates = self.userLocation
        let marker = GMSMarker(position: coordinates)
        marker.map = self.googleMapView
        self.googleMapView.animate(toLocation: coordinates)
        let config = GMSPlacePickerConfig(viewport: viewport)
        placePicker = GMSPlacePicker(config: config)

        self.placePicker?.pickPlace(callback: { (place: GMSPlace?, error: NSError?) -> Void in
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
                let placeLoc = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
                if (loc.distance(from: placeLoc) > 3000.0){
                    let alertController = UIAlertController(title: "Error", message: "The selected location is too far away from your location", preferredStyle: UIAlertControllerStyle.alert)
                    alertController.addAction(UIAlertAction(title:"Dismiss", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
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
    
    @objc(didUpdateAutocompletePredictionsForTableDataSource:) func didUpdateAutocompletePredictions(for tableDataSource: GMSAutocompleteTableDataSource) {
        // Turn the network activity indicator off.
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        // Reload table data.
        srchDisplayController?.searchResultsTableView.reloadData()
    }
    
    @objc(didRequestAutocompletePredictionsForTableDataSource:) func didRequestAutocompletePredictions(for tableDataSource: GMSAutocompleteTableDataSource) {
        // Turn the network activity indicator on.
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        // Reload table data.
        srchDisplayController?.searchResultsTableView.reloadData()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations[0].coordinate
        print("\(userLocation.latitude) Degrees Latitude, \(userLocation.longitude) Degrees Longitude")
        locationUpdated = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print(complete)
        print(saved)
        if (complete == false){
            takeAndSave()
        }else if (complete == true && saved == false){
            
            dismiss(animated: true, completion: nil)
            
        }else{
            var searchedTypes = ["bar"]
            //fetchNearbyPlaces(userLocation, searchedTypes: searchedTypes)
            //tableView.reloadData()
            
            searchPlaces()
        }

    }
    

    

    func takeAndSave(){
        
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            
            print("captureVideoPressed and camera available.")
            
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            imagePicker.sourceType = .camera;
            //imagePicker.mediaTypes = [kUTTypeMovie!]
            imagePicker.allowsEditing = false
            
            imagePicker.showsCameraControls = true

            self.present(imagePicker, animated: true, completion: nil)
            complete = true
            
        }
            
        else {
            print("Camera not available.")
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:[String : Any]) {
        
        self.selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        //selectedImageView.image = self.selectedImage
        dismiss(animated: true, completion: nil)
        saved = true
        locationManager.stopUpdatingLocation()
        
        
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    



    func saveImageInfo(_ sender: UIButton!){
        let tempImage = self.selectedImage
        let dataImage:Data = UIImageJPEGRepresentation(tempImage, 0.0)!
        let date = Date()
        let setImageTitle : String = self.chosenLocation
        let setId : String = UUID().uuidString
        var imageURL = ""
        let myImage : Image = Image()
        AWSService().saveImageToBucket(dataImage, id: setId, placeName: setImageTitle, completion: {(result)->Void in
             DispatchQueue.main.async(execute: {
            imageURL = result
            myImage.imageID = setId
            myImage.placeTitle = setImageTitle
            myImage.caption = self.textField.text
            myImage.eventID = UUID().uuidString
            myImage.picTakenLat = self.userLocation.latitude
            myImage.picTakenLong = self.userLocation.longitude
            myImage.owner = (self.user?.userName)!
            myImage.userID = (self.user?.userID)!
            myImage.hotColdScore = 0
            myImage.placeLat = self.chosenLatFromMap
            myImage.placeLong = self.chosenLongFromMap
            myImage.url = imageURL
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            myImage.timePosted = formatter.string(from: date)
            myImage.totalScore = 0
            var geo :Geohash = Geohash()
           let l =  CLLocationCoordinate2DMake((self.locationManager.location?.coordinate.latitude)!, (self.locationManager.location?.coordinate.longitude)!)
            let s = l.geohash(10)
            let index = s.characters.index(s.endIndex, offsetBy: -7)
            myImage.geohash = s.substring(to: index)
            AWSService().save(myImage)
            })
            
        })
        

        
        
        print("saved successfully", terminator: "")
        dismiss(animated: true, completion: nil)
        tabBarController?.selectedIndex = 0
    }

    func loadCaptionView(){
        self.view.isHidden = false
        pickLocNav.topItem!.title = "Add Caption"
        //tableView.hidden = true
        //textField = UITextField(frame: CGRect(x: self.view.frame.origin.x, y: self.view.frame.origin.y, width: self.view.frame.width, height: self.view.frame.height * 0.5))
        textField.becomeFirstResponder()
        textField.textColor = UIColor.black
        textField.backgroundColor = UIColor.white
        textField.autocorrectionType = UITextAutocorrectionType.default
        textField.keyboardType = UIKeyboardType.default
        textField.font = UIFont (name: "HelveticaNeue", size: 20)
        /*UITextField.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            
                self.textField.frame.origin.y =  (self.textField.frame.origin.y - self.view.frame.height - 5) + self.pickLocNav.frame.height
            }, completion: nil)*/
        
        
        submitButton = UIButton(frame: CGRect(x: self.view.frame.width * 0.50, y: self.view.frame.height * 0.50,width: self.view.frame.width * 0.5 - 10, height: 40 ))
        submitButton.backgroundColor = UIColor(red: 0.9294, green: 0.8667, blue: 0, alpha: 1.0)
        submitButton.setTitle("Post", for: UIControlState())
        submitButton.layer.cornerRadius = 5
        submitButton.isEnabled = true
        submitButton.layer.opacity = 1.0
        submitButton.setTitleColor(UIColor.gray, for: UIControlState())
        submitButton.titleLabel!.font = UIFont(name:
            "HelveticaNeue-Medium", size: 18)
        submitButton.addTarget(self, action: #selector(PickLocationController.saveImageInfo(_:)), for: UIControlEvents.touchUpInside)
        self.view.addSubview(submitButton)
        
        
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if (textField.text?.isEmpty == false){
            submitButton.isEnabled = true;
            submitButton.layer.opacity = 1.0
            submitButton.setTitleColor(UIColor.black, for: UIControlState())
        }
    }
    
}

extension PickLocationController: GMSAutocompleteTableDataSourceDelegate {
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didAutocompleteWith place: GMSPlace) {
        srchDisplayController?.isActive = false
        // Do something with the selected place.
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress)")
        print("Place attributions: \(place.attributions)")
    }
    
    @objc(searchDisplayController:shouldReloadTableForSearchString:) func searchDisplayController(_ controller: UISearchDisplayController, shouldReloadTableForSearch searchString: String?) -> Bool {
        tableDataSource?.sourceTextHasChanged(searchString)
        return false
    }
    
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didFailAutocompleteWithError error: Error) {
        // TODO: Handle the error.
        print("Error: \(error.localizedDescription)")
    }
    
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didSelect prediction: GMSAutocompletePrediction) -> Bool {
        return true
    }
}
