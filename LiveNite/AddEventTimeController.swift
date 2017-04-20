//
//  AddEventTimeController.swift
//  LiveNite
//
//  Created by Kevin  on 12/19/16.
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

class AddEventTimeController: UIViewController, UIImagePickerControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout,  CLLocationManagerDelegate,UITextFieldDelegate, UINavigationControllerDelegate{
    var eventForm = EventForm()
    var minDate = Date()
    var maxDate = Date()
    
    override func viewDidLoad(){
        super.viewDidLoad()
        startText.layer.borderColor = UIColor.white.cgColor
        endText.layer.borderColor = UIColor.white.cgColor
        startText.backgroundColor = UIColor.white
        endText.backgroundColor = UIColor.white
        startText.textColor = UIColor.black
        endText.textColor = UIColor.black
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.short
        if (eventForm.startTime != nil){
            startText.text = " " + dateFormatter.string(from: eventForm.startTime)
            minDate = eventForm.startTime
        }else{
            startText.text = " " + dateFormatter.string(from: Date())
        }
        if (eventForm.endTime != nil){
            maxDate = eventForm.endTime
            endText.text = " " + dateFormatter.string(from: eventForm.endTime)

        }else{
            endText.text = " " + dateFormatter.string(from: Date())
        }
        
    }
    
    
    @IBOutlet weak var startText: UITextField!
    
    @IBOutlet weak var endText: UITextField!
    
    @IBAction func startTextFieldEdit(_ sender: UITextField) {
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.maximumDate = maxDate
        if (eventForm.endTime != nil){
            datePickerView.maximumDate = eventForm.endTime
        }
        datePickerView.datePickerMode = UIDatePickerMode.dateAndTime
        sender.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(AddEventTimeController.startDatePickerValueChanged), for: UIControlEvents.valueChanged)
    }
    @IBAction func endTextEdit(_ sender: UITextField) {
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.minimumDate = minDate
        if (eventForm.startTime != nil){
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
    }
    
    func endDatePickerValueChanged(sender: UIDatePicker){
        eventForm.endTime = sender.date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.short
        minDate = eventForm.startTime
        endText.text = " " + dateFormatter.string(from: sender.date)
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool){
        if let controller = viewController as? AddEventController{
            //controller.whenLabel.text = String(describing: timePicker?.date)
        }
    }
    @IBAction func exit(_ sender: AnyObject) {
        //eventForm.time = (timePicker?.date)!
        
        self.dismiss(animated: false, completion: nil)
        
    }
}
