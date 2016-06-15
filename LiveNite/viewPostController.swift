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
import JSSAlertView

class viewPostController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate{

    @IBOutlet weak var captionLabel: UILabel!
    var locationManager = CLLocationManager()
    var userLocation = CLLocation()
    var locationUpdated = false
    var userID = 0
    var userNameOP = ""
    
    @IBAction func checkIn(sender: AnyObject) {
        
        let imageLocationFetchRequest = NSFetchRequest(entityName: "Entity")
        imageLocationFetchRequest.predicate = NSPredicate(format: "id = %i", imageID)
        let imageLocationFetchResults = (try? context.executeFetchRequest(imageLocationFetchRequest)) as! [NSManagedObject]?
        if let imageLocationFetchResults = imageLocationFetchResults{
            for result in imageLocationFetchResults{
                print(result)
                //get distance between user and place
                let latitude : AnyObject? = result.valueForKey("titleLatitude")
                let imageLatitude = latitude as! Double
                let longitude : AnyObject? = result.valueForKey("titleLongitude")
                let imageLongitude = longitude as! Double
                let titleLocation = CLLocation(latitude: imageLatitude, longitude: imageLongitude)
                let distanceBetweenUserandTitle : CLLocationDistance = titleLocation.distanceFromLocation(userLocation)
                let maxAllowableDistance : CLLocationDistance = 2500
                print(distanceBetweenUserandTitle)
                
                //if within range, check if they've checked in recently
                if distanceBetweenUserandTitle < maxAllowableDistance {
                    
                    //get title of location and date of last check in
                    let title = result.valueForKey("title") as! String
                    let currentDate = NSDate()
                    let checkInFetchRequest = NSFetchRequest(entityName: "UserCheckIns")
                    print("Current User Name: \(userNameOP)")
                    checkInFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "locationTitle= %@",title), NSPredicate(format: "userName= %@", userNameOP)])
                    let checkInResult = (try? context.executeFetchRequest(checkInFetchRequest)) as! [NSManagedObject]?
                    //If the fetch request returns nothing, we know it is a new location they are checking into
                    if (checkInResult! == []){
                        //Make new check in in table
                        if let newCheckIn = NSEntityDescription.insertNewObjectForEntityForName("UserCheckIns", inManagedObjectContext:context) as? NSManagedObject{
                    
                            newCheckIn.setValue(userNameOP as NSString, forKey: "userName")
                            newCheckIn.setValue(currentDate, forKey: "dateOfLastCheckIn")
                            newCheckIn.setValue(title as NSString, forKey: "locationTitle")
                            do {
                                try context.save()
                            } catch _ {
                            }
                            
                        }
                        //Award user points
                        print("userID: \(userID)")
                        let scoreFetchRequest = NSFetchRequest(entityName: "Users")
                        scoreFetchRequest.predicate = NSPredicate(format: "id = \(userID)")
                        let scores = (try? context.executeFetchRequest(scoreFetchRequest)) as! [NSManagedObject]?
                        if let scores = scores{
                            for score in scores{
                                score.setValue(score.valueForKey("score") as! Int + 5, forKey: "score")
                                print("Score: \(score.valueForKey("score") as! Int)")
                            }
                        }
                            JSSAlertView().show(self, title: "Congrats", text : "You have just been awarded five points!", buttonText: "OK", color: UIColorFromHex(0x33cc33, alpha: 1))
                    } else {
                        if let checkInResult = checkInResult{
                            for result in checkInResult{
                                let lastCheckIn : NSDate = result.valueForKey("dateOfLastCheckIn") as! NSDate
                                var diffDateComponents = NSCalendar.currentCalendar().components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second], fromDate: lastCheckIn, toDate: currentDate, options: NSCalendarOptions.init(rawValue: 0))
                                
                                print("The difference between dates is: \(diffDateComponents.year) years, \(diffDateComponents.month) months, \(diffDateComponents.day) days, \(diffDateComponents.hour) hours, \(diffDateComponents.minute) minutes, \(diffDateComponents.second) seconds")
                                if (diffDateComponents.year > 0 || diffDateComponents.month > 0 || diffDateComponents.day > 0){
                                    print("It's been a while")
                                    //award points
                                    print("userID: \(userID)")
                                    let scoreFetchRequest = NSFetchRequest(entityName: "Users")
                                    scoreFetchRequest.predicate = NSPredicate(format: "id = \(userID)")
                                    let scores = (try? context.executeFetchRequest(scoreFetchRequest)) as! [NSManagedObject]?
                                    if let scores = scores{
                                        for score in scores{
                                            score.setValue(score.valueForKey("score") as! Int + 5, forKey: "score")
                                            print("Score: \(score.valueForKey("score") as! Int)")
                                        }
                                    }
                                    //update check in date
                                    result.setValue(currentDate, forKey: "dateOfLastCheckIn")
                                    JSSAlertView().show(self, title: "Congrats", text : "You have just been awarded five points!", buttonText: "OK", color: UIColorFromHex(0x33cc33, alpha: 1))
                                } else{
                                        JSSAlertView().show(self, title: "Sorry", text : "You have already checked in to this location is the past 24 hours.", buttonText: "OK", color: UIColorFromHex(0xff3333, alpha: 1))
                                    print("You've checked in within the last 24 hours")
                                }

                            }
                        }

                    }
                    
                } else {
                    print("not close enough to check in")
                }
                
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations[0]
        print("\(userLocation.coordinate.latitude) Degrees Latitude, \(userLocation.coordinate.longitude) Degrees Longitude")
        locationUpdated = true
    }
    
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
    
    @IBOutlet weak var userNameLabel: UILabel!
    var imageTapped = UIImage()
    var imageID = 0
    var imageUpvotes = 0
    var imageTitle =  ""
    var caption = ""
    var userName = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUIDetails()
        loadImageDetail()
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func loadUIDetails() {
        
        detailView.backgroundColor = UIColor.clearColor()
        print(userID)
        let navBarBGImage = UIImage(named: "Navigation_Bar_Gold")
        navigationBar.setBackgroundImage(navBarBGImage, forBarMetrics: .Default)
        navigationBar.topItem!.title = imageTitle
        var userUpvoteStatus : Int = 0
        
        let userUpvoteStatusFetchRequest = NSFetchRequest(entityName: "UserUpvotes")
        let userUpvoteStatusFetchResults = (try? context.executeFetchRequest(userUpvoteStatusFetchRequest)) as! [NSManagedObject]?
        if let userUpvoteStatusFetchResults = userUpvoteStatusFetchResults{
            for result in userUpvoteStatusFetchResults{
                let idData : AnyObject? = result.valueForKey("image_id")
                let id = idData as! Int
                let upvoteData : AnyObject? = result.valueForKey("upvote_value")
                let upvoteStatus = upvoteData as! Int
                let userData : AnyObject? = result.valueForKey("user_name")
                let userName = userData as! String
                if userName == userNameOP && id == imageID {
                    userUpvoteStatus = upvoteStatus
                }
            }
        }
        captionLabel.text = caption
        captionLabel.textColor = UIColor.whiteColor()
        userNameLabel.text = userName
        userNameLabel.textColor = UIColor.whiteColor()
        if userUpvoteStatus == 1{
            upvoteButton.alpha = 0.5
        } else if userUpvoteStatus == -1{
            downvoteButton.alpha = 0.5
        }
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

        var userUpvoteStatus : Int = 0
        //get user upvote status
        let userUpvoteStatusFetchRequest = NSFetchRequest(entityName: "UserUpvotes")
        userUpvoteStatusFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "image_id= %i",imageID), NSPredicate(format: "user_name= %@", userNameOP)])
        let userUpvoteStatusFetchResults = (try? context.executeFetchRequest(userUpvoteStatusFetchRequest)) as! [NSManagedObject]?
        if let userUpvoteStatusFetchResults = userUpvoteStatusFetchResults{
            for result in userUpvoteStatusFetchResults{
                let upvoteData : AnyObject? = result.valueForKey("upvote_value")
                userUpvoteStatus = upvoteData as! Int
            }
        }
        //get image upvote data and manipulate based on upvote status
        let fetchRequest = NSFetchRequest(entityName: "Entity")
        fetchRequest.predicate = NSPredicate(format: "id = %i", sender.tag)
        print(fetchRequest.predicate)
        let images = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        var upvote = 0
        if let images = images{
            for image in images{
                let idData : AnyObject? = image.valueForKey("id")
                let id = idData as! Int
                print(id, terminator: "")
                let upvoteData : AnyObject? = image.valueForKey("upvotes")
                upvote = upvoteData as! Int
                var change = 0
                if userUpvoteStatus == 0 {
                    change = 1
                    userUpvoteStatus = 1
                    upvoteButton.alpha = 0.5
                } else if userUpvoteStatus == 1 {
                    change = -1
                    userUpvoteStatus = 0
                    upvoteButton.alpha = 1.0
                } else if userUpvoteStatus == -1 {
                    change = 2
                    userUpvoteStatus = 1
                    upvoteButton.alpha = 0.5
                    downvoteButton.alpha = 1.0
                } else {
                    print("userUpvoteStatus is not a valid number")
                }
                let OPUserName = image.valueForKey("userOP") as! String
                upvote = upvote + change
                let OPFetchRequest = NSFetchRequest(entityName: "Users")
                fetchRequest.predicate = NSPredicate(format: "user_name = %@", OPUserName)
                let OPUser = (try? context.executeFetchRequest(OPFetchRequest)) as! [NSManagedObject]?
                if let OPUser = OPUser{
                    for user in OPUser{
                        user.setValue(user.valueForKey("score") as! Int + change, forKey: "score")
                    }
                }
                image.setValue(upvote, forKey: "upvotes")
                do {
                    try context.save()
                } catch _ {
                }
            }
        }
        print(imageID)
        //save data in core data
        userVoted(imageID, user_name: userNameOP, upvote_value: userUpvoteStatus)
        upvotesLabel.text = String(upvote)
        //self.collectionView!.reloadData()
        
    }
    
    func userVoted(id : Int, user_name : String, upvote_value : Int){
        let fetchRequest = NSFetchRequest(entityName: "UserUpvotes")
        fetchRequest.predicate = NSPredicate(format: "image_id= %i", id)
        let imageVote = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        //If the fetch request returns nothing, we know that it is a new image vote
        print("user upvoted")
        if (imageVote! == []){
            if let newImageVote = NSEntityDescription.insertNewObjectForEntityForName("UserUpvotes", inManagedObjectContext:context) as? NSManagedObject{
            //For each "column" set your values
                newImageVote.setValue(imageID, forKey: "image_id")
                newImageVote.setValue(user_name, forKey: "user_name")
                newImageVote.setValue(upvote_value, forKey: "upvote_value")
            }
        } else{
            //just change value for appropriate image user pair
            if let imageVote = imageVote{
                for image in imageVote{
                    if image.valueForKey("image_id") as! Int == imageID && image.valueForKey("user_name") as! String == user_name {
                        image.setValue(upvote_value, forKey: "upvote_value")
                    }
                }
                
            }
        }
        let userFetchRequest = NSFetchRequest(entityName: "Entity")
        userFetchRequest.predicate = NSPredicate(format: "id = %i", imageID)
        var OP : String = ""
        let user = (try? context.executeFetchRequest(userFetchRequest)) as! [NSManagedObject]?
        if let user = user{
            OP = user[0].valueForKey("userOP") as! String
            print("User: \(OP)")
        }
        let scoreFetchRequest = NSFetchRequest(entityName: "Users")
        scoreFetchRequest.predicate = NSPredicate(format: "user_name = %@", OP)
        let scores = (try? context.executeFetchRequest(scoreFetchRequest)) as! [NSManagedObject]?
        if let scores = scores{
            for score in scores{
                print("Score: \(score.valueForKey("score") as! Int)")
            }
        }
    }
    
    func DownVote(sender: UIButton){
        
        var userUpvoteStatus : Int = 0
        //get upvote status
        let userUpvoteStatusFetchRequest = NSFetchRequest(entityName: "UserUpvotes")
        userUpvoteStatusFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "image_id= %i",imageID), NSPredicate(format: "user_name= %@", userID)])
        let userUpvoteStatusFetchResults = (try? context.executeFetchRequest(userUpvoteStatusFetchRequest)) as! [NSManagedObject]?
        if let userUpvoteStatusFetchResults = userUpvoteStatusFetchResults{
            for result in userUpvoteStatusFetchResults{
                let upvoteData : AnyObject? = result.valueForKey("upvote_value")
                userUpvoteStatus = upvoteData as! Int
            }
        }
        //get image upvote data and manipulate based on upvote status
        let fetchRequest = NSFetchRequest(entityName: "Entity")
        fetchRequest.predicate = NSPredicate(format: "id = %i", sender.tag)
        print(fetchRequest.predicate)
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
                var change = 0
                if userUpvoteStatus == 0 {
                    change = -1
                    userUpvoteStatus = -1
                    downvoteButton.alpha = 0.5
                } else if userUpvoteStatus == 1 {
                    change = -2
                    userUpvoteStatus = -1
                    downvoteButton.alpha = 0.5
                    upvoteButton.alpha = 1.0
                } else if userUpvoteStatus == -1 {
                    change = 1
                    userUpvoteStatus = 0
                    downvoteButton.alpha = 1.0
                } else {
                    print("userUpvoteStatus is not a valid number")
                }
                upvote = upvote + change
                let OPUserName = loc.valueForKey("userOP") as! String
                let OPFetchRequest = NSFetchRequest(entityName: "Users")
                fetchRequest.predicate = NSPredicate(format: "user_name = %@", OPUserName)
                let OPUser = (try? context.executeFetchRequest(OPFetchRequest)) as! [NSManagedObject]?
                if let OPUser = OPUser{
                    for user in OPUser{
                        user.setValue(user.valueForKey("score") as! Int + change, forKey: "score")
                    }
                }
                loc.setValue(upvote, forKey: "upvotes")
                do {
                    try context.save()
                } catch _ {
                }
            }
        }
        //save data in core data
        userVoted(imageID, user_name: userNameOP, upvote_value: userUpvoteStatus)
        upvotesLabel.text = String(upvote)
    }
    
    @IBAction func viewComments(sender: AnyObject) {
                self.performSegueWithIdentifier("viewComments", sender: sender.tag)
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "viewComments" {
            if let destinationVC = segue.destinationViewController as? CommentController{
                
                destinationVC.imageID = (imageID as? Int)!
            }
        }
        
    }
}