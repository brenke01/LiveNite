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

class viewPostController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate{

    var locationManager = CLLocationManager()
    var userLocation = CLLocation()
    var locationUpdated = false
    
    @IBAction func checkIn(sender: AnyObject) {
        
        let imageLocationFetchRequest = NSFetchRequest(entityName: "Entity")
        imageLocationFetchRequest.predicate = NSPredicate(format: "id = %i", imageID)
        let imageLocationFetchResults = (try? context.executeFetchRequest(imageLocationFetchRequest)) as! [NSManagedObject]?
        if let imageLocationFetchResults = imageLocationFetchResults{
            for result in imageLocationFetchResults{
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
                    print("Current User Name: \(currentUserName)")
                    checkInFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "locationTitle= %@",title), NSPredicate(format: "userName= %@", currentUserName)])
                    let checkInResult = (try? context.executeFetchRequest(checkInFetchRequest)) as! [NSManagedObject]?
                    //If the fetch request returns nothing, we know it is a new location they are checking into
                    if (checkInResult! == []){
                        //Make new check in in table
                        if let newCheckIn = NSEntityDescription.insertNewObjectForEntityForName("UserCheckIns", inManagedObjectContext:context) as? NSManagedObject{
                    
                            newCheckIn.setValue(currentUserName as NSString, forKey: "userName")
                            newCheckIn.setValue(currentDate, forKey: "dateOfLastCheckIn")
                            newCheckIn.setValue(title as NSString, forKey: "locationTitle")
                            do {
                                try context.save()
                            } catch _ {
                            }
                            
                        }
                        //Award user points
                        print("currentUserName: \(currentUserName)")
                        let scoreFetchRequest = NSFetchRequest(entityName: "Users")
                        scoreFetchRequest.predicate = NSPredicate(format: "id = \(currentUserName)")
                        let scores = (try? context.executeFetchRequest(scoreFetchRequest)) as! [NSManagedObject]?
                        if let scores = scores{
                            for score in scores{
                                score.setValue(score.valueForKey("score") as! Int + 5, forKey: "score")
                                print("Score: \(score.valueForKey("score") as! Int)")
                            }
                        }
                    } else {
                        if let checkInResult = checkInResult{
                            for result in checkInResult{
                                let lastCheckIn : NSDate = result.valueForKey("dateOfLastCheckIn") as! NSDate
                                var diffDateComponents = NSCalendar.currentCalendar().components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second], fromDate: lastCheckIn, toDate: currentDate, options: NSCalendarOptions.init(rawValue: 0))
                                
                                print("The difference between dates is: \(diffDateComponents.year) years, \(diffDateComponents.month) months, \(diffDateComponents.day) days, \(diffDateComponents.hour) hours, \(diffDateComponents.minute) minutes, \(diffDateComponents.second) seconds")
                                if (diffDateComponents.year > 0 || diffDateComponents.month > 0 || diffDateComponents.day > 0){
                                    print("It's been a while")
                                    //award points
                                    print("currentUserName: \(currentUserName)")
                                    let scoreFetchRequest = NSFetchRequest(entityName: "Users")
                                    scoreFetchRequest.predicate = NSPredicate(format: "id = \(currentUserName)")
                                    let scores = (try? context.executeFetchRequest(scoreFetchRequest)) as! [NSManagedObject]?
                                    if let scores = scores{
                                        for score in scores{
                                            score.setValue(score.valueForKey("score") as! Int + 5, forKey: "score")
                                            print("Score: \(score.valueForKey("score") as! Int)")
                                        }
                                    }
                                    //update check in date
                                    result.setValue(currentDate, forKey: "dateOfLastCheckIn")
                                } else{
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
    
    var imageTapped = UIImage()
    var imageID = 0
    var imageUpvotes = 0
    var imageTitle =  ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUIDetails()
        loadImageDetail()
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func loadUIDetails() {
        
        print(currentUserName)
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
                if userName == currentUserName && id == imageID {
                    userUpvoteStatus = upvoteStatus
                }
            }
        }
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
        let userUpvoteStatusFetchResults = (try? context.executeFetchRequest(userUpvoteStatusFetchRequest)) as! [NSManagedObject]?
        if let userUpvoteStatusFetchResults = userUpvoteStatusFetchResults{
            for result in userUpvoteStatusFetchResults{
                let idData : AnyObject? = result.valueForKey("image_id")
                let id = idData as! Int
                let upvoteData : AnyObject? = result.valueForKey("upvote_value")
                let upvoteStatus = upvoteData as! Int
                let userData : AnyObject? = result.valueForKey("user_name")
                let userName = userData as! String
                if userName == currentUserName && id == imageID {
                    userUpvoteStatus = upvoteStatus
                }
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
                let OPUserName = loc.valueForKey("userOP") as! String
                upvote = upvote + change
                let OPFetchRequest = NSFetchRequest(entityName: "Users")
                fetchRequest.predicate = NSPredicate(format: "id = %@", OPUserName)
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
        print(imageID)
        //save data in core data
        userVoted(imageID, user_name: currentUserName, upvote_value: userUpvoteStatus)
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
        scoreFetchRequest.predicate = NSPredicate(format: "id = \(OP)")
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
        let userUpvoteStatusFetchResults = (try? context.executeFetchRequest(userUpvoteStatusFetchRequest)) as! [NSManagedObject]?
        if let userUpvoteStatusFetchResults = userUpvoteStatusFetchResults{
            for result in userUpvoteStatusFetchResults{
                print("Loop in upvote")
                let idData : AnyObject? = result.valueForKey("image_id")
                let id = idData as! Int
                let upvoteData : AnyObject? = result.valueForKey("upvote_value")
                let upvoteStatus = upvoteData as! Int
                let userData : AnyObject? = result.valueForKey("user_name")
                let userName = userData as! String
                if userName == currentUserName && id == imageID {
                    userUpvoteStatus = upvoteStatus
                }
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
                fetchRequest.predicate = NSPredicate(format: "id = %@", OPUserName)
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
        userVoted(imageID, user_name: currentUserName, upvote_value: userUpvoteStatus)
        upvotesLabel.text = String(upvote)
    }
}