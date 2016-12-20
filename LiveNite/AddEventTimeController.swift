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
    @IBOutlet weak var timePicker : UIDatePicker?
    var eventForm = EventForm()
    
    override func viewDidLoad(){
        super.viewDidLoad()
        navigationController?.delegate = self

    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool){
        if let controller = viewController as? AddEventController{
            controller.whenLabel.text = String(describing: timePicker?.date)
        }
    }
    @IBAction func exit(_ sender: AnyObject) {
        eventForm.time = (timePicker?.date)!
        
        self.dismiss(animated: false, completion: nil)
        
    }
}
