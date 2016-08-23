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
import AWSDynamoDB
import AWSS3

class viewPostController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate{

    @IBOutlet weak var captionLabel: UILabel!
    var locationManager = CLLocationManager()
    var userLocation = CLLocation()
    var locationUpdated = false
    var userID = ""
    var userNameOP = ""
    var imageTapped = UIImage()
    var imageID = ""
    var imageUpvotes = 0
    var imageTitle =  ""
    var caption = ""
    var userName = ""
    var hotColdScore = 0.0
    
    @IBAction func checkIn(sender: AnyObject) {
        
        //create date formatter to allow conversion of dates to string and vice versa throughout function
        //set current date
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let currentDate = NSDate()
        
        //fetch image data for post
        let imageData : Image = AWSService().loadImage(imageID)
        
        //determine distance between user and place and set maxAllowableDistance
        let imagePlaceLocation = CLLocation(latitude: imageData.placeLat, longitude: imageData.placeLong)
        let distanceBetweenUserAndPlace : CLLocationDistance = imagePlaceLocation.distanceFromLocation(userLocation)
        let maxAllowableDistance : CLLocationDistance = 2500
        
        //if within range, check if they've checked in recently
        if distanceBetweenUserAndPlace < maxAllowableDistance {

            //fetch check in
            let checkInRequest : CheckIn = AWSService().loadCheckIn(self.userID + "_" + imageData.placeTitle)
            
            //If the userID was not set, then the checkInRequest doesn't exist in the db and it is a new check in
            if (checkInRequest.userID == ""){
                
                //Make new check in in table
                let checkIn : CheckIn = CheckIn()
                checkIn.checkInID = self.userID + "_" + imageData.placeTitle
                checkIn.checkInTime = dateFormatter.stringFromDate(currentDate)
                checkIn.placeTitle = imageData.placeTitle
                checkIn.userID = self.userID
                AWSService().save(checkIn)
                
                //Award user points
                print("userID: \(userID)")
                let user : User = AWSService().loadUser(self.userID, newUserName: "")
                user.score += 5
                AWSService().save(user)
                print("Score: \(user.score)")
                JSSAlertView().show(self, title: "Congrats", text : "You have just been awarded five points!", buttonText: "OK", color: UIColorFromHex(0x33cc33, alpha: 1))
                
            } else {
                //if it did set the userID, they've checked in there before so we need to see how long it's been
                
                //get last check in date
                let lastCheckIn : NSDate = dateFormatter.dateFromString(checkInRequest.checkInTime)!
                
                //get the difference in date components
                var diffDateComponents = NSCalendar.currentCalendar().components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second], fromDate: lastCheckIn, toDate: currentDate, options: NSCalendarOptions.init(rawValue: 0))
                
                 print("The difference between dates is: \(diffDateComponents.year) years, \(diffDateComponents.month) months, \(diffDateComponents.day) days, \(diffDateComponents.hour) hours, \(diffDateComponents.minute) minutes, \(diffDateComponents.second) seconds")
                
                //if it has been more than a day award the user points and update the check in time
                if (diffDateComponents.year > 0 || diffDateComponents.month > 0 || diffDateComponents.day > 0){
                    print("It's been a while")
                    
                    //Award user points
                    print("userID: \(userID)")
                    let user : User = AWSService().loadUser(self.userID, newUserName: "")
                    user.score += 5
                    AWSService().save(user)
                    print("Score: \(user.score)")
                    
                    //Update check in date
                    checkInRequest.checkInTime = dateFormatter.stringFromDate(currentDate)
                    AWSService().save(checkInRequest)
                    
                    //Notify user of successful check in
                    JSSAlertView().show(self, title: "Congrats", text : "You have just been awarded five points!", buttonText: "OK", color: UIColorFromHex(0x33cc33, alpha: 1))
                    
                } else {
                    //if it's been less than a day, let them know they've checked in too recently
                    JSSAlertView().show(self, title: "Sorry", text : "You have already checked in to this location is the past 24 hours.", buttonText: "OK", color: UIColorFromHex(0xff3333, alpha: 1))
                    print("You've checked in within the last 24 hours")
                }
                
            }
        }else {
            //if they aren't within range, let them know they aren't close enough to check in
            JSSAlertView().show(self, title: "Sorry", text : "You are not close enough to check in.", buttonText: "OK", color: UIColorFromHex(0xff3333, alpha: 1))
            print("not close enough to check in")
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
        calculateHotColdScore()
        upvotesLabel.text = String(imageUpvotes)
        //Needs styling
        upvotesLabel.textColor = UIColor.whiteColor()
    }
    
    func calculateHotColdScore(){
        //retrieve all userUpvotes for imageID
        var a = -1000.0
        var flatnessFactor = 3.0
        let fetchRequest = NSFetchRequest(entityName: "UserUpvotes")
        fetchRequest.predicate = NSPredicate(format: "image_id= %i", imageID)
        let imageVote = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        if let imageVote = imageVote{
            for image in imageVote{
                let timeVote = image.valueForKey("time") as! NSDate
                let hoursSinceVote = Double(NSDate().timeIntervalSinceDate(timeVote))/3600.0
                let userUpvoteValue = image.valueForKey("upvote_value") as! Double
                let decayedValue = userUpvoteValue*max(a*pow(hoursSinceVote,flatnessFactor)+1, 0)
                hotColdScore = hotColdScore + decayedValue
            }
        }
        print(hotColdScore)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    /*
     
    Hot/Cold Score Algorithm Pseudocode
    
     -When upvote or downvote occurs, store the time it occurred as well
     Calculate time since upvote and downvote, apply decaying function to it
     
        Decaying function:
            -a * t^flatnessFactor + 1
        Where a is the initial value, r is the rate of decay, and t is the time that has passed
     
     Sum up resulting decayed votes to calculate final score
     Store score somewhere near location of picture
     Fetch location of picture
     Fetch all pictures within the determined radius of comparison
     Determine appropriate statistical values of the population of pictures
        Need to determine how to set final score, potential options:
            Base it on statistical deviation from the mean
            Base it as a percentage of the maximum score
            Base it as a percentage of the range
     Assign picture to bucket values:
     
        1 - Frozen
        2 - Cold
        3 - Warm
        4 - Hot
        5 - Fire
     
     Display value on sliding bar or some other UI feature
     
    */
    
    
    
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
                let timeNow = NSDate()
                newImageVote.setValue(timeNow, forKey: "time")
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
                destinationVC.userNameOP = (userNameOP as? String)!
                destinationVC.userName = (userName as? String)!
            }
        }
        
    }
}