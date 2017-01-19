//
//  AddEventTitleController.swift
//  LiveNite
//
//  Created by Kevin  on 11/16/16.
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

class AddEventTitleController: UIViewController, UIImagePickerControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout,  CLLocationManagerDelegate,UITextFieldDelegate, UINavigationControllerDelegate{
    @IBOutlet weak var textField : UITextView?
    @IBAction func doneTyping(_ sender: AnyObject){
        
    }
    var eventForm = EventForm()

    override func viewDidLoad(){
        super.viewDidLoad()
        navigationController?.delegate = self
        textField?.becomeFirstResponder()
        textField?.textColor = UIColor.black
        textField?.backgroundColor = UIColor.white
        textField?.autocorrectionType = UITextAutocorrectionType.default
        textField?.keyboardType = UIKeyboardType.default
        if (textField?.text != ""){
            textField?.text = eventForm.titleInput
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool){
            if let controller = viewController as? AddEventController{
                controller.locLabel.text = textField?.text
            }
        }
    @IBAction func exit(_ sender: AnyObject) {
        eventForm.titleInput = (textField?.text)!

        self.dismiss(animated: false, completion: nil)

    }
}
