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
    
    
    @IBAction func postComment(sender: AnyObject) {
        let comment : Comment = Comment()
        let uuid = NSUUID().UUIDString
        comment.commentID = uuid
        comment.imageID = self.imageID
        comment.comment = commentField.text
        comment.owner = self.userName
        comment.date = String(NSDate())
        comment.eventID = ""
        AWSService().save(comment)
        dismissViewControllerAnimated(true, completion: nil)
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
    @IBOutlet weak var navBar: UINavigationBar!
    var imageID = "";
    var userName = "";
    
    override func viewDidLoad() {
        let navBarBGImage = UIImage(named: "Navigation_Bar_Gold")
        navBar.setBackgroundImage(navBarBGImage, forBarMetrics: .Default)
        navBar.topItem!.title = "Post Comment"
        super.viewDidLoad()
        commentField.becomeFirstResponder()
        commentField.textColor = UIColor.blackColor()
        commentField.backgroundColor = UIColor.whiteColor()
        commentField.autocorrectionType = UITextAutocorrectionType.Default
        commentField.keyboardType = UIKeyboardType.Default
        commentField.font = UIFont (name: "HelveticaNeue", size: 20)
        postCommentButton.backgroundColor = UIColor.yellowColor()
        postCommentButton.layer.cornerRadius = 5
        

        
    }
    
    
}
