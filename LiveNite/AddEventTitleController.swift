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

class AddEventTitleController: UIViewController, UIImagePickerControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout,  CLLocationManagerDelegate,UITextFieldDelegate, UITextViewDelegate,UINavigationControllerDelegate{
    @IBOutlet weak var charCount: UILabel!

    @IBOutlet weak var titleTextField : UITextView?
    @IBAction func doneTyping(_ sender: AnyObject){
        
    }
    var eventForm = EventForm()

    @IBOutlet weak var doneButton: UIBarButtonItem!
    override func viewDidLoad(){
        super.viewDidLoad()

    }
    

    
    
    func textViewDidChange(_ textView: UITextView) {
        let count = 25 - textView.text.utf16.count
        if (textView.text?.isEmpty == false && count >= 0){
            doneButton.isEnabled = true;
            charCount.textColor = UIColor.darkGray.withAlphaComponent(0.75)
        }else if count < 0{
            charCount.textColor = UIColor.red.withAlphaComponent(0.75)
            doneButton.isEnabled = false;

        }else{
            charCount.textColor = UIColor.darkGray.withAlphaComponent(0.75)
            doneButton.isEnabled = false;

        }
        
        
        charCount.text = String(count)
        
        
    }
    func textView(_ textView: UITextView, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newLength = (textView.text?.utf16.count)! + string.utf16.count - range.length
        //charCount.text = String(newLength)
        // Find out what the text field will be after adding the current edit
        let text = (textView.text! as NSString).replacingCharacters(in: range, with: string)
        
        
        // Return true so the text field will be changed
        return newLength <= 25
        return true
    }
}
