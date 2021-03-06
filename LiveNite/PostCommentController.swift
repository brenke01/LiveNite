//
//  PostCommentController.swift
//  LiveNite
//
//  Created by Kevin  on 6/21/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import CoreData
import GoogleMaps

class PostCommentController: UIViewController,  UINavigationControllerDelegate,  UIScrollViewDelegate,  UITextFieldDelegate, UITextViewDelegate {
    
    @IBAction func postComment(_ sender: AnyObject) {
        let comment : Comment = Comment()
        let uuid = UUID().uuidString
        comment.commentID = uuid
        if (event?.eventID != nil && event?.eventID != ""){
            comment.eventID = (event?.eventID)!
            comment.imageID = (event?.eventID)!
        }else{
            comment.eventID = "-1"
            comment.imageID = (self.imageObj?.imageID)!
        }


        comment.comment = commentField.text
        comment.ownerName = (self.user?.userName)!
        comment.date = String(describing: Date())
        comment.timePosted = String(describing: Date())
        var notifUUID = UUID().uuidString
        var notification = Notification()
        notification?.notificationID = notifUUID
        notification?.userName = (self.user?.userName)!
        notification?.ownerName = (self.imageObj?.ownerName)!
        var date = Date()
        notification?.actionTime = String(describing: date)
        notification?.imageID = (self.imageObj?.imageID)!
        notification?.open = true
        notification?.type = "comment"
        var dayComponent = DateComponents()
        dayComponent.day = 1
        var cal = Calendar.current
        var nextDay = cal.date(byAdding: dayComponent, to: date)
        var nextDayEpoch = UInt64(floor((nextDay?.timeIntervalSince1970)!))
        notification?.expirationDate = Int(nextDayEpoch)
        AWSService().save(notification!)
        AWSService().save(comment)
        
    }
    
    @IBOutlet weak var charCount: UILabel!

    @IBOutlet weak var postCommentButton: UIButton!
    @IBOutlet weak var commentField: UITextView!
    
    var event = Event()
    var imageID = "";
    var imageObj = Image()
    var user = User()
    
    var typing = true
    
    override func viewDidLoad() {

        super.viewDidLoad()

        charCount.text = "300"
        commentField.delegate = self
        charCount.textColor = UIColor.darkGray.withAlphaComponent(0.75)
        commentField.becomeFirstResponder()
        commentField.textColor = UIColor.black
        commentField.backgroundColor = UIColor.white
        commentField.autocorrectionType = UITextAutocorrectionType.default
        commentField.keyboardType = UIKeyboardType.default
        commentField.font = UIFont (name: "HelveticaNeue", size: 20)
        self.view.bringSubview(toFront: charCount)

        self.navigationController?.navigationBar.tintColor = UIColor.white
        navigationItem.title = "Post Comment"
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        var barButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(self.back(_:)))
        barButton.title = "Back"
        barButton.image = UIImage(named: "backBtn")
        
        self.navigationItem.leftBarButtonItem = barButton
    }
    
    func back(_ sender: UIBarButtonItem){
        _ = navigationController?.popViewController(animated: true)
    }
    
    @IBAction func exit(_ sender: AnyObject) {
        self.dismiss(animated: false, completion: nil)
        
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let count = 300 - textView.text.utf16.count
        if (textView.text?.isEmpty == false && count >= 0){
            postCommentButton.isUserInteractionEnabled = true;
            postCommentButton.layer.opacity = 1.0
            charCount.textColor = UIColor.darkGray.withAlphaComponent(0.75)
        }else if count < 0{
            charCount.textColor = UIColor.red.withAlphaComponent(0.75)
            postCommentButton.isUserInteractionEnabled = false;
            postCommentButton.layer.opacity = 0.5
        }else{
            charCount.textColor = UIColor.darkGray.withAlphaComponent(0.75)
            postCommentButton.isUserInteractionEnabled = false;
            postCommentButton.layer.opacity = 0.5
        }
        
        
        charCount.text = String(count)
        
        
    }
    func textView(_ textView: UITextView, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newLength = (textView.text?.utf16.count)! + string.utf16.count - range.length
        //charCount.text = String(newLength)
        // Find out what the text field will be after adding the current edit
        let text = (textView.text! as NSString).replacingCharacters(in: range, with: string)
        
        
        // Return true so the text field will be changed
        return newLength <= 300
        return true
    }
}
