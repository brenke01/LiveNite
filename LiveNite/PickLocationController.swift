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
import GooglePlaces
import GooglePlacePicker
import SCLAlertView


class PickLocationController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout, UITableViewDelegate, CLLocationManagerDelegate, UITextViewDelegate, UISearchDisplayDelegate, UITextFieldDelegate, UITabBarControllerDelegate, AVCaptureMetadataOutputObjectsDelegate{
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet weak var charCount: UILabel!
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
    var qrCodeFrameView : UIView?
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
    var fromEvent = false
    var eventPlacePicked = false
    var eventSaved = false
    var lastIndex = 0
    var eventForm = EventForm()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textField.delegate = self
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 10, width: 250.0, height: 44.0))
        self.view.addSubview(textField)
        tabBarController?.delegate = self
        srchDisplayController = UISearchDisplayController(searchBar: searchBar!, contentsController: self)
        srchDisplayController?.searchResultsDataSource = tableDataSource
        srchDisplayController?.searchResultsDelegate = tableDataSource
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
        self.currentUserName = (self.user?.userID)!
        
        
    }
    @IBAction func exit(_ sender: AnyObject) {
     
            pickLocNav.topItem!.title = "Pick Location"
            //self.submitButton.removeFromSuperview()
            //self.textField.removeFromSuperview()
        dismiss(animated: true, completion: nil)
        searchPlaces()
            
        
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        self.lastIndex = (self.tabBarController?.selectedIndex)!
        print("\(self.tabBarController?.selectedIndex)")
        return true
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
        placePicker?.pickPlace(callback: {(place: GMSPlace?, error) in
    
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
                if (loc.distance(from: placeLoc) > 1000.0){

                    self.searchPlaces()
                    SCLAlertView().showError("Error", subTitle: "The selected location is too far away from your location.")
                }else{
                    self.chosenLocation = place.name
                    self.mapPickedLocation = true
                    self.chosenLatitude = place.coordinate.latitude
                    self.chosenLongitude = place.coordinate.longitude
                    if (self.fromEvent){
                        self.eventForm.eventPlacePicked = true
                        self.performSegue(withIdentifier: "addEventDesc", sender: 1)

                    }else{
                        self.loadCaptionView()
                    }
                    
                }
                
            } else {
                self.textField.endEditing(true)
                self.view.isHidden = true
                self.takeAndSave()
                self.saved = false
                print("No place selected")
            }
        })
    
    
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "addEventDesc"{
            
            if let destinationVC = segue.destination as? AddEventController{
                destinationVC.userLocation = self.userLocation
                destinationVC.selectedImg = self.selectedImage
                destinationVC.userID = (self.user?.userID)!
                destinationVC.placeTitle = self.chosenLocation
                destinationVC.placeLat = self.chosenLatitude
                destinationVC.placeLong = self.chosenLongitude
                destinationVC.user = self.user
                destinationVC.eventForm = eventForm
            
            }
        }
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
        textField.delegate = self
        print(complete)
        print(saved)
        if (complete == false){
            takeAndSave()
        }else if (complete == true && saved == false || eventSaved == true){
            complete = false
            saved = false
            dismiss(animated: true, completion: nil)
            tabBarController?.selectedIndex = self.lastIndex
        }else if (eventForm.eventSaved){
            complete = false
            saved = false
            dismiss(animated: true, completion: nil)
        
            
        }else if (!eventForm.eventPlacePicked){
            searchPlaces()
        }else{
            takeAndSave()
        }

    }
    

    

    func takeAndSave(){
        
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            
            print("captureVideoPressed and camera available.")
            
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            imagePicker.sourceType = .camera;
            //imagePicker.mediaTypes = [kUTTypeMovie!]
            imagePicker.allowsEditing = true
            
            imagePicker.showsCameraControls = true

            self.present(imagePicker, animated: true, completion: nil)
            complete = true
            
        }
            
        else {
            print("Camera not available.")
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:[String : Any]) {
        
        self.selectedImage = info[UIImagePickerControllerEditedImage] as! UIImage
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
        let dataImage:Data = UIImageJPEGRepresentation(tempImage, 1.0)!
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
            myImage.ownerName = (self.user?.userName)!
            myImage.userID = (self.user?.userID)!
            myImage.hotColdScore = 0
            myImage.placeLat = self.chosenLatFromMap
            myImage.placeLong = self.chosenLongFromMap
            myImage.url = imageURL
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            myImage.timePosted = formatter.string(from: date)
                var dayComponent = DateComponents()
                dayComponent.day = 1
                var cal = Calendar.current
                var nextDay = cal.date(byAdding: dayComponent, to: date)
                var nextDayEpoch = UInt64(floor((nextDay?.timeIntervalSince1970)!))
                    myImage.expirationDate = Int(nextDayEpoch)
                
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
        //reset progress checkers 
        self.saved = false
        self.complete = false
        dismiss(animated: true, completion: nil)
        tabBarController?.selectedIndex = 0
    }
    
    func textView(_ textView: UITextView, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newLength = (textView.text?.utf16.count)! + string.utf16.count - range.length
        //charCount.text = String(newLength)
        // Find out what the text field will be after adding the current edit
        let text = (textView.text! as NSString).replacingCharacters(in: range, with: string)
        
        if !text.isEmpty{//Checking if the input field is not empty
            submitButton.isUserInteractionEnabled = true
            submitButton.alpha = 1.0
            //Enabling the button
        } else {
            submitButton.isUserInteractionEnabled = false
            submitButton.alpha = 0.5
            //Disabling the button
        }
        
        // Return true so the text field will be changed
        return newLength <= 300
        return true
    }

    func loadCaptionView(){
       
        textField.delegate = self
        textField.text = ""
        self.view.isHidden = false
         charCount.text = "300"
        charCount.textColor = UIColor.darkGray.withAlphaComponent(0.75)
        pickLocNav.topItem!.title = "Add Caption"
        textField.becomeFirstResponder()
        textField.textColor = UIColor.black
        textField.backgroundColor = UIColor.white
        textField.autocorrectionType = UITextAutocorrectionType.default
        textField.keyboardType = UIKeyboardType.default
        textField.font = UIFont (name: "HelveticaNeue", size: 20)
        
        self.view.bringSubview(toFront: charCount)
        submitButton = UIButton(frame: CGRect(x: 0, y: self.view.frame.height * 0.54,width: self.view.frame.width, height: 50 ))
        submitButton.backgroundColor = ViewController().hexStringToUIColor(hex: "#3869CB")
        submitButton.setTitleColor(UIColor.white, for: .normal)
        submitButton.setTitle("Post", for: UIControlState())
        submitButton.isEnabled = true
        submitButton.layer.opacity = 1.0
        submitButton.setTitleColor(UIColor.white, for: UIControlState())
        submitButton.titleLabel!.font = UIFont(name:
            "HelveticaNeue-Medium", size: 18)
        submitButton.addTarget(self, action: #selector(PickLocationController.saveImageInfo(_:)), for: UIControlEvents.touchUpInside)
        self.view.addSubview(submitButton)
        if textField.text.isEmpty{
            submitButton.isUserInteractionEnabled = false
            submitButton.alpha = 0.5
        }
        
        
        
        
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if (textView.text?.isEmpty == false){
            submitButton.isUserInteractionEnabled = true;
            submitButton.layer.opacity = 1.0
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let count = 300 - textView.text.utf16.count
        if (textView.text?.isEmpty == false && count >= 0){
            submitButton.isUserInteractionEnabled = true;
            submitButton.layer.opacity = 1.0
            charCount.textColor = UIColor.darkGray.withAlphaComponent(0.75)
        }else if count < 0{
            charCount.textColor = UIColor.red.withAlphaComponent(0.75)
            submitButton.isUserInteractionEnabled = false;
            submitButton.layer.opacity = 0.5
        }else{
            charCount.textColor = UIColor.darkGray.withAlphaComponent(0.75)
            submitButton.isUserInteractionEnabled = false;
            submitButton.layer.opacity = 0.5
        }
        
        
        charCount.text = String(count)
        
      
    }
    

    
}

extension PickLocationController: GMSAutocompleteTableDataSourceDelegate {
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didAutocompleteWith place: GMSPlace) {
        srchDisplayController?.isActive = false
        // Do something with the selected place.
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
