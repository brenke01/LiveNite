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

class AddEventController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout,  CLLocationManagerDelegate, UITabBarControllerDelegate, UITextViewDelegate, UITextFieldDelegate{
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var locLabelBG: UIView!
    @IBOutlet weak var postButton: UIButton!

    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var privateLabelBG: UIView!
    @IBOutlet weak var descLabelBG: UIView!
    @IBOutlet weak var whenLabelBG: UIView!
    @IBOutlet weak var whenLabel: UILabel!
    @IBOutlet weak var titleLabelBG: UIView!
    @IBOutlet weak var privateToggle: UISwitch!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var titleInput: UITextField!
    @IBOutlet weak var locLabel: UILabel!
    
        @IBOutlet weak var titleCharCount: UILabel!
        @IBOutlet weak var descCharCount: UILabel!
    
    
    
    
    @IBOutlet weak var titleTextField : UITextView?
    @IBOutlet weak var descTextField : UITextView?


    var selectedImg = UIImage()
    var userID = ""
    var placeTitle = ""
    var placeLat = 0.0
    var placeLong = 0.0
    var userLocation = CLLocationCoordinate2D()
    var eventForm = EventForm()
    var user = User()
    var minDate = Date()
    var maxDate = Date()
    var titleEdited = false
    var descEdited = false
    var titleValid = false
    var descValid = false
    var isVideo = false
    var videoData = Data()
    var videoURL : URL!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        postButton.isEnabled = false
        postButton.alpha = 0.5
        if (isVideo){
            let asset = AVURLAsset.init(url: self.videoURL)
            let gen = AVAssetImageGenerator(asset: asset)
            gen.appliesPreferredTrackTransform = true
            let timestamp = CMTime(seconds: 1, preferredTimescale: 60 )
            do {
                let imageRef = try gen.copyCGImage(at: timestamp, actualTime: nil)
                imgView.image = UIImage(cgImage: imageRef)
                var iconView = UIImageView(frame: CGRect(x: imgView.frame.width * 0.8, y: imgView.frame.height * 0.05, width: imgView.frame.width * 0.15, height: imgView.frame.height * 0.1))
                
                var videoIcon = UIImage(named: "videoCamera")
                iconView.image = videoIcon
                imgView.addSubview(iconView)
                
            }catch let error as NSError{
                print(error)
            }

        }else{
            imgView.image = selectedImg
        }
        titleTextField?.tag = 1
        descTextField?.tag = 2
        titleCharCount.text = "25"
        descCharCount.text = "250"
        titleCharCount.textColor = UIColor.lightGray
        descCharCount.textColor = UIColor.lightGray
        titleTextField?.delegate = self
        descTextField?.delegate = self
        descTextField?.layer.cornerRadius = 2
        titleTextField?.layer.cornerRadius = 2
        self.privateToggle.isOn = false
        startText.layer.cornerRadius = 2
        endText.layer.cornerRadius = 2
        navigationController?.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: "dissmissKeyboard")
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "backgroundimg" )!)
        view.addGestureRecognizer(tap)
        tabBarController?.delegate = self
       
    }
    
    @IBAction func addTitle(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "addTitle", sender: 1)
    }
    @IBAction func addDesc(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "addDesc", sender: 1)
    }
    
    @IBAction func addTime(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "addTime", sender: 1)
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
        }else if segue.identifier == "addTime"{
            
            if let destinationVC = segue.destination as? AddEventTimeController{
                destinationVC.eventForm = eventForm
            }
        }
    }

    func dissmissKeyboard(){
        view.endEditing(true)
    }
    
    func back(_ sender: UIBarButtonItem){
        _ = navigationController?.popViewController(animated: true)
    }
    
    func saveImageToBucket(){
        let setId : String = UUID().uuidString
        var dataImage:Data = Data()
        var event = Event()

        if (self.isVideo){
            dataImage = self.videoData
            event?.isVideo = true
        }else{
            dataImage = UIImageJPEGRepresentation(selectedImg, 1.0)!
        }
        AWSService().saveImageToBucket(dataImage, id: setId, placeName: placeTitle, isVideo: self.isVideo, completion: {(result)->Void in
        DispatchQueue.main.async(execute: {
            var imageURL = result
            event?.url = imageURL
            let eventID : String = UUID().uuidString
            event?.eventID = eventID
            event?.eventLat = self.placeLat
            event?.eventLong = self.placeLong
            event?.information = (self.descTextField?.text)!
            event?.publicStatus = self.privateToggle.isOn
            event?.placeTitle = self.placeTitle
            event?.eventTitle = (self.titleTextField?.text)!
            let date = Date()
            var dayComponent = DateComponents()
            dayComponent.day = 1
            var cal = Calendar.current
            var nextDay = cal.date(byAdding: dayComponent, to: self.eventForm.endTime)
            var nextDayEpoch = UInt64(floor((nextDay?.timeIntervalSince1970)!))
            event?.expirationDate = Int(nextDayEpoch)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            event?.timePosted = formatter.string(from: date)
            event?.eventStartTime = formatter.string(from: self.eventForm.startTime)
            event?.eventEndTime = formatter.string(from: self.eventForm.endTime)
            var geo :Geohash = Geohash()
            let l =  self.userLocation
            let s = l.geohash(10)
            let index = s.characters.index(s.endIndex, offsetBy: -7)
            event?.geohash = s.substring(to: index)
            event?.ownerName = (self.user?.userName)!
            event?.ownerID = (self.user?.userID)!
            event?.totalScore = 0
            AWSService().save(event!)
            self.eventForm.eventSaved = true
            self.tabBarController?.selectedIndex = 1
           self.dismiss(animated: true, completion: nil)
            self.view.window!.rootViewController?.dismiss(animated: (false), completion: nil)
           self.navigationController?.popToRootViewController(animated: true)
            PickLocationController().dismiss(animated: false, completion: {
                
            })
            
        })
        })
    }
    
    @IBAction func unwindToEvents(segue : UIStoryboardSegue){
        
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool{
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func postEvent(_ sender: AnyObject) {
        saveImageToBucket()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    @IBAction func exit(_ sender: Any) {
        eventForm.eventPlacePicked = false
        self.dismiss(animated: false, completion: nil)

    }
    
    @IBOutlet weak var startText: UITextField!
    
    @IBOutlet weak var endText: UITextField!
    
    @IBAction func startTimeEdit(_ sender: UITextField) {
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.minimumDate = minDate
        if (eventForm.endTime != nil && !(endText.text?.isEmpty)!){
            datePickerView.maximumDate = eventForm.endTime
        }
        datePickerView.datePickerMode = UIDatePickerMode.dateAndTime
        sender.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(AddEventTimeController.startDatePickerValueChanged), for: UIControlEvents.valueChanged)
    }
    @IBAction func endTimeEdit(_ sender: UITextField) {
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.minimumDate = minDate
        if (eventForm.startTime != nil && !(startText.text?.isEmpty)!){
            datePickerView.minimumDate = eventForm.startTime
        }
        datePickerView.datePickerMode = UIDatePickerMode.dateAndTime
        sender.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(AddEventTimeController.endDatePickerValueChanged), for: UIControlEvents.valueChanged)
    }
    
    
    func startDatePickerValueChanged(sender: UIDatePicker){
        eventForm.startTime = sender.date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.short
        maxDate = eventForm.endTime
        
        startText.text = " " + dateFormatter.string(from: sender.date)
        var valid = checkInputs()
        if (valid){
            postButton.alpha = 1.0
            postButton.isEnabled = true
        }else{
            postButton.alpha = 0.5
            postButton.isEnabled = false
        }
    }
    
    func endDatePickerValueChanged(sender: UIDatePicker){
        eventForm.endTime = sender.date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.short
        minDate = eventForm.startTime
        endText.text = " " + dateFormatter.string(from: sender.date)
        var valid = checkInputs()
        if (valid){
            postButton.alpha = 1.0
            postButton.isEnabled = true
        }else{
            postButton.alpha = 0.5
            postButton.isEnabled = false
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        var charLength = 0
        if (textView.tag == 1 ){
            charLength = 25
        }else{
            charLength = 250
        }
        let count = charLength - textView.text.utf16.count
        if (textView.text?.isEmpty == false && count >= 0){
            if (textView.tag == 1 ){
            titleCharCount.textColor = UIColor.darkGray.withAlphaComponent(0.75)
                 titleCharCount.text = String(count)
                titleValid = true
            }else{
                  descCharCount.textColor = UIColor.darkGray.withAlphaComponent(0.75)
                descCharCount.text = String(count)
                descValid = true
            }
        }else if count < 0{
            if (textView.tag == 1 ){
            titleCharCount.textColor = UIColor.red.withAlphaComponent(0.75)
                 titleCharCount.text = String(count)
                titleValid = false
            }else{
                  descCharCount.textColor = UIColor.darkGray.withAlphaComponent(0.75)
                descCharCount.text = String(count)
                descValid = false
            }
           
            
        }else{
            if (textView.tag == 1 ){
            titleCharCount.textColor = UIColor.darkGray.withAlphaComponent(0.75)
                 titleCharCount.text = String(count)
            }else{
                descCharCount.textColor = UIColor.darkGray.withAlphaComponent(0.75)
                 descCharCount.text = String(count)
            }
            titleValid = false
            descValid = false
            
        }
        
        
       
        
        
    }
    func textView(_ textView: UITextView, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var charLength = 0
        if (textView.tag == 1 ){
            charLength = 25
        }else{
            charLength = 250
        }
        let newLength = (textView.text?.utf16.count)! + string.utf16.count - range.length
        //charCount.text = String(newLength)
        // Find out what the text field will be after adding the current edit
        let text = (textView.text! as NSString).replacingCharacters(in: range, with: string)
        
        
        // Return true so the text field will be changed
        return newLength <= charLength
        return true
    }
    
    func checkInputs() -> Bool{
        var valid = true
        if (!self.titleValid || !self.descValid){
            valid = false
        }
        if ((startText.text?.isEmpty)! || (endText.text?.isEmpty)!){
            valid = false
        }

        return valid
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if (textView.tag == 1 && !self.titleEdited){
            self.titleEdited = true
            titleTextField?.text = ""
        }else if textView.tag == 2 && !self.descEdited{
            self.descEdited = true
            descTextField?.text = ""
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        var valid = checkInputs()
        if (valid){
            postButton.alpha = 1.0
            postButton.isEnabled = true
        }else{
            postButton.alpha = 0.5
            postButton.isEnabled = false
        }
    }
    
    
}
