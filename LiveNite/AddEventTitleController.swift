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

class AddEventTitleController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout,  CLLocationManagerDelegate,UITextFieldDelegate{
    @IBOutlet weak var textField : UITextView?
    @IBAction func doneTyping(_ sender: AnyObject){
        
    }
    override func viewDidLoad(){
        super.viewDidLoad()
        textField?.becomeFirstResponder()
        textField?.textColor = UIColor.black
        textField?.backgroundColor = UIColor.white
        textField?.autocorrectionType = UITextAutocorrectionType.default
        textField?.keyboardType = UIKeyboardType.default
    }
}
