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

class PostEventCommentController: UIViewController,  UINavigationControllerDelegate,  UIScrollViewDelegate,  UITextFieldDelegate {
    
    
    @IBAction func postComment(_ sender: AnyObject) {
        let comment : Comment = Comment()
        let uuid = UUID().uuidString
        comment.commentID = uuid

        comment.imageID = (self.event?.eventID)!
        comment.eventID = (self.event?.eventID)!
        
        
        comment.comment = commentField.text
        comment.ownerName = (self.user?.userName)!
        comment.date = String(describing: Date())
        comment.timePosted = String(describing: Date())
        
        AWSService().save(comment)
        
    }
    
    @IBOutlet weak var postCommentButton: UIButton!
    @IBOutlet weak var commentField: UITextView!
    
    var event = Event()
    var imageID = "";
    var imageObj = Image()
    var user = User()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        commentField.becomeFirstResponder()
        commentField.textColor = UIColor.black
        commentField.backgroundColor = UIColor.white
        commentField.autocorrectionType = UITextAutocorrectionType.default
        commentField.keyboardType = UIKeyboardType.default
        commentField.font = UIFont (name: "HelveticaNeue", size: 20)
        self.navigationController?.navigationBar.tintColor = UIColor.white
        navigationItem.title = "Post Comment"
        
        
        
    }
    
    @IBAction func exit(_ sender: AnyObject) {
        self.dismiss(animated: false, completion: nil)
        
    }
}
