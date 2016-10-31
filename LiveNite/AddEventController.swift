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

class AddEventController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout,  CLLocationManagerDelegate{
    

    @IBOutlet weak var descInput: UITextView!
    @IBOutlet weak var privateToggle: UISwitch!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var titleInput: UITextField!
    @IBOutlet weak var locLabel: UILabel!
    var selectedImg = UIImage()
    var userID = ""
    var placeTitle = ""
    var placeLat = 0.0
    var placeLong = 0.0
    
    
    override func viewDidLoad(){
        super.viewDidLoad()
        imgView.image = selectedImg
        locLabel.text = placeTitle
        let tap = UITapGestureRecognizer(target: self, action: "dissmissKeyboard")
        view.addGestureRecognizer(tap)
        
       
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
            event?.information = self.descInput.text
            event?.publicStatus = self.privateToggle.isOn
            event?.placeTitle = self.placeTitle
            event?.eventTitle = self.titleInput.text!
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            event?.timePosted = formatter.string(from: date)
            event?.eventStartTime = formatter.string(from: date)
            event?.eventEndTime = formatter.string(from: date)
            AWSService().save(event!)
            dismiss(animated: true, completion: nil)
            tabBarController?.selectedIndex = 1
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
    
}
