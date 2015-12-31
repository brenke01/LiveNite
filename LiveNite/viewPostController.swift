//
//  viewPostController.swift
//  LiveNite
//
//  Created by Jacob Pierce on 12/28/15.
//  Copyright © 2015 LiveNite. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer
import MobileCoreServices
import AVFoundation
import CoreData
import CoreLocation
import GoogleMaps

class viewPostController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout{

    @IBAction func exit(sender: AnyObject) {
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    @IBAction func upvoteAction(sender: AnyObject) {
        upvoteButton.tag = imageID
        UpVote(upvoteButton)
    }
    
    @IBAction func downvoteAction(sender: AnyObject) {
        downvoteButton.tag = imageID
        DownVote(downvoteButton)
    }
    
    @IBOutlet weak var upvotesLabel: UILabel!
    @IBOutlet weak var detailView: UIView!
    @IBOutlet var imgView: UIImageView!
    @IBOutlet var upvoteButton: UIButton!
    @IBOutlet var downvoteButton: UIButton!
    @IBOutlet var navigationBar: UINavigationBar!
    
    var imageTapped = UIImage()
    var imageID = 0
    var imageUpvotes = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUIDetails()
        loadImageDetail()
        
    }
    
    func loadUIDetails() {
        
        let navBarBGImage = UIImage(named: "Navigation_Bar_Gold")
        navigationBar.setBackgroundImage(navBarBGImage, forBarMetrics: .Default)
        
    }
    
    func loadImageDetail(){
        imgView.image = imageTapped
        upvotesLabel.text = String(imageUpvotes)
        //Needs styling
        upvotesLabel.textColor = UIColor.whiteColor()
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func UpVote(sender: UIButton){
        print("Upvote")
        print(sender.tag, terminator: "")
        let id = 0
        let disableMyButton = sender as UIButton
        disableMyButton.enabled = false
        disableMyButton.alpha = 0.5
        let fetchRequest = NSFetchRequest(entityName: "Entity")
        fetchRequest.predicate = NSPredicate(format: "id = %i", sender.tag)
        let locations = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        var upvote = 0
        if let locations = locations{
            
            for loc in locations{
                print("Loop")
                let idData : AnyObject? = loc.valueForKey("id")
                let id = idData as! Int
                print(id, terminator: "")
                let upvoteData : AnyObject? = loc.valueForKey("upvotes")
                upvote = upvoteData as! Int
                upvote = upvote + 1
                
                loc.setValue(upvote, forKey: "upvotes")
                do {
                    try context.save()
                } catch _ {
                }
                
                
                
            }
            
            
            
            
            
            
        }
        userUpvoted(id)
        upvotesLabel.text = String(upvote)
        //self.collectionView!.reloadData()
        
    }
    
    func userUpvoted(id : Int){
        
    }
    
    func DownVote(sender: UIButton){
        print(sender.tag, terminator: "")
        let fetchRequest = NSFetchRequest(entityName: "Entity")
        fetchRequest.predicate = NSPredicate(format: "id = %i", sender.tag)
        let locations = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        var upvote = 0
        if let locations = locations{
            
            for loc in locations{
                
                let idData : AnyObject? = loc.valueForKey("id")
                let id = idData as! Int
                print(id, terminator: "")
                let upvoteData : AnyObject? = loc.valueForKey("upvotes")
                upvote = upvoteData as! Int
                upvote = upvote - 1
                loc.setValue(upvote, forKey: "upvotes")
                do {
                    try context.save()
                } catch _ {
                }
                
                
                
            }
            
            
            
            
            
            
        }
        upvotesLabel.text = String(upvote)
        //self.collectionView?.reloadData()
        
    }

}