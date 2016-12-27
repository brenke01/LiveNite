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

class PostCommentController: UIViewController,  UINavigationControllerDelegate,  UIScrollViewDelegate,  UITextFieldDelegate {
    
    
    @IBAction func postComment(_ sender: AnyObject) {
        let comment : Comment = Comment()
        let uuid = UUID().uuidString
        comment.commentID = uuid
        comment.imageID = (self.imageObj?.imageID)!
        comment.comment = commentField.text
        comment.owner = (self.imageObj?.userID)!
        comment.date = String(describing: Date())
        comment.timePosted = String(describing: Date())
        comment.eventID = "-1"
        AWSService().save(comment)
        dismiss(animated: true, completion: nil)
//        if let newComment = NSEntityDescription.insertNewObjectForEntityForName("Comments", inManagedObjectContext:context) as? NSManagedObject{
//            let owner = self.userName
//            let id = self.imageID
//            let comment = commentField.text
//            let date = NSDate()
//            newComment.setValue(date, forKey: "time_posted")
//            newComment.setValue(id, forKey: "image_id")
//            newComment.setValue(owner, forKey: "owner")
//            newComment.setValue(comment, forKey: "comment")
//            do {
//                try context.save()
//            } catch _ {
//            }
//            
//            
//        }
    }
    
    @IBOutlet weak var postCommentButton: UIButton!
    @IBOutlet weak var commentField: UITextView!

    var imageID = "";
    var userName = "";
    var imageObj = Image()
    
    override func viewDidLoad() {

        super.viewDidLoad()
        commentField.becomeFirstResponder()
        commentField.textColor = UIColor.black
        commentField.backgroundColor = UIColor.white
        commentField.autocorrectionType = UITextAutocorrectionType.default
        commentField.keyboardType = UIKeyboardType.default
        commentField.font = UIFont (name: "HelveticaNeue", size: 20)
        self.navigationController?.navigationBar.tintColor = UIColor.white
        

        
    }
    
    @IBAction func exit(_ sender: AnyObject) {
        self.dismiss(animated: false, completion: nil)
        
    }
}
