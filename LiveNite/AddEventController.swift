//
//  AddEvent.swift
//  LiveNite
//
//  Created by Kevin  on 10/25/16.
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

class AddEventController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout,  CLLocationManagerDelegate, UITabBarControllerDelegate{
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var locLabelBG: UIView!

    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var privateLabelBG: UIView!
    @IBOutlet weak var descLabelBG: UIView!
    @IBOutlet weak var titleLabelBG: UIView!
    @IBOutlet weak var privateToggle: UISwitch!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var titleInput: UITextField!
    @IBOutlet weak var locLabel: UILabel!
    var selectedImg = UIImage()
    var userID = ""
    var placeTitle = ""
    var placeLat = 0.0
    var placeLong = 0.0
    var userLocation = CLLocationCoordinate2D()
    var eventForm = EventForm()
    
    override func viewDidLoad(){
        super.viewDidLoad()
        imgView.image = selectedImg
        locLabel.text = placeTitle
        titleLabel.text = eventForm.titleInput
        descLabel.text = eventForm.descInput
        navigationController?.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: "dissmissKeyboard")
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "backgroundimg" )!)
        view.addGestureRecognizer(tap)
        locLabelBG.backgroundColor? = UIColor.black.withAlphaComponent(0.2)
        titleLabelBG.backgroundColor? = UIColor.black.withAlphaComponent(0.2)
        descLabelBG.backgroundColor? = UIColor.black.withAlphaComponent(0.2)
        privateLabelBG.backgroundColor? = UIColor.black.withAlphaComponent(0.2)
        privateLabelBG.layer.borderWidth = 1
        privateLabelBG.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        titleLabelBG.layer.borderWidth = 1
        titleLabelBG.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        locLabelBG.layer.borderWidth = 1
        locLabelBG.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        descLabelBG.layer.borderWidth = 1
        descLabelBG.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        tabBarController?.delegate = self
       
    }
    
    @IBAction func addTitle(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "addTitle", sender: 1)
    }
    @IBAction func addDesc(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "addDesc", sender: 1)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "addTitle"{
            
            if let destinationVC = segue.destination as? AddEventTitleController{
                destinationVC.eventForm = eventForm

                
            }
        }else if segue.identifier == "addDesc"{
            
            if let destinationVC = segue.destination as? AddEventDescriptionController{
                destinationVC.eventForm = eventForm
            }
        }
    }

    func dissmissKeyboard(){
        view.endEditing(true)
    }
    
    func saveImageToBucket(){
        let setId : String = UUID().uuidString
        let dataImage:Data = UIImageJPEGRepresentation(self.selectedImg, 0.0)!
        AWSService().saveImageToBucket(dataImage, id: setId, placeName: placeTitle, completion: {(result)->Void in
        DispatchQueue.main.async(execute: {
            var imageURL = result
            var event = Event()
            event?.url = imageURL
            let eventID : String = UUID().uuidString
            event?.eventID = eventID
            event?.eventLat = self.placeLat
            event?.eventLong = self.placeLong
            event?.information = self.descLabel.text!
            event?.publicStatus = self.privateToggle.isOn
            event?.placeTitle = self.placeTitle
            event?.eventTitle = self.titleLabel.text!
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            event?.timePosted = formatter.string(from: date)
            event?.eventStartTime = formatter.string(from: date)
            event?.eventEndTime = formatter.string(from: date)
            var geo :Geohash = Geohash()
            let l =  self.userLocation
            let s = l.geohash(10)
            let index = s.characters.index(s.endIndex, offsetBy: -7)
            event?.geohash = s.substring(to: index)
            AWSService().save(event!)
           self.dismiss(animated: true, completion: nil)
            self.view.window!.rootViewController?.dismiss(animated: (false), completion: nil)
           self.navigationController?.popToRootViewController(animated: true)
            self.tabBarController?.selectedIndex = 1
        })
        })
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool{
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func postEvent(_ sender: AnyObject) {
        saveImageToBucket()
        
    }
    
    override func viewWillAppear(_ animated: Bool){
        titleLabel.text = eventForm.titleInput
        descLabel.text = eventForm.descInput
        super.viewWillAppear(animated)
    }
    
}
