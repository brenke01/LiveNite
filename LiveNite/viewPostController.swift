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
    
    //IBOutlet zone

    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var upvotesLabel: UILabel!
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet var imgView: UIImageView!
    @IBOutlet var upvoteButton: UIButton!
    @IBOutlet var downvoteButton: UIButton!
    @IBOutlet var navigationBar: UINavigationBar!
    
    //end IBOutlet zone
    
//----------------------------------------------
    
    //var zone
    
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
    var user = User()
    var imageData = Image()
    var checkInRequest = CheckIn()
    
    //end var zone
    
//----------------------------------------------
    
    //IBAction zone
    
    @IBAction func checkIn(sender: AnyObject) {
        
        //create date formatter to allow conversion of dates to string and vice versa throughout function
        //set current date
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let currentDate = NSDate()
        
        //fetch image data for post

        
        //determine distance between user and place and set maxAllowableDistance
        let imagePlaceLocation = CLLocation(latitude: self.imageData.placeLat, longitude: self.imageData.placeLong)
        let distanceBetweenUserAndPlace : CLLocationDistance = imagePlaceLocation.distanceFromLocation(userLocation)
        let maxAllowableDistance : CLLocationDistance = 2500
        
        //if within range, check if they've checked in recently
        if distanceBetweenUserAndPlace < maxAllowableDistance {

            
            
            //If the userID was not set, then the checkInRequest doesn't exist in the db and it is a new check in
            if (self.checkInRequest.userID == ""){
                
                //Make new check in in table
                let checkIn : CheckIn = CheckIn()
                checkIn.checkInID = self.userID + "_" + self.imageData.placeTitle
                checkIn.checkInTime = dateFormatter.stringFromDate(currentDate)
                checkIn.placeTitle = self.imageData.placeTitle
                checkIn.userID = self.userID
                AWSService().save(checkIn)
                
                //Award user points
                print("userID: \(userID)")
                AWSService().loadUser(self.userID,completion: {(result)->Void in
                    self.user = result
                    print("user id is ")
                    print(self.user.userID)
                })
                user.score += 5
                AWSService().save(user)
                print("Score: \(user.score)")
                JSSAlertView().show(self, title: "Congrats", text : "You have just been awarded five points!", buttonText: "OK", color: UIColorFromHex(0x33cc33, alpha: 1))
                
            } else {
                //if it did set the userID, they've checked in there before so we need to see how long it's been
                
                //get last check in date
                let lastCheckIn : NSDate = dateFormatter.dateFromString(self.checkInRequest.checkInTime)!
                
                //get the difference in date components
                let diffDateComponents = NSCalendar.currentCalendar().components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second], fromDate: lastCheckIn, toDate: currentDate, options: NSCalendarOptions.init(rawValue: 0))
                
                 print("The difference between dates is: \(diffDateComponents.year) years, \(diffDateComponents.month) months, \(diffDateComponents.day) days, \(diffDateComponents.hour) hours, \(diffDateComponents.minute) minutes, \(diffDateComponents.second) seconds")
                
                //if it has been more than a day award the user points and update the check in time
                if (diffDateComponents.year > 0 || diffDateComponents.month > 0 || diffDateComponents.day > 0){
                    print("It's been a while")
                    
                    //Award user points
                    print("userID: \(userID)")
                    AWSService().loadUser(self.userID,completion: {(result)->Void in
                        self.user = result
                    })

                    user.score += 5
                    AWSService().save(user)
                    print("Score: \(user.score)")
                    
                    //Update check in date
                    self.checkInRequest.checkInTime = dateFormatter.stringFromDate(currentDate)
                    AWSService().save(self.checkInRequest)
                    
                    //Notify user of successful check in
                    JSSAlertView().show(self, title: "Congrats", text : "You have just been awarded five points!", buttonText: "OK", color: UIColorFromHex(0x33cc33, alpha: 1))
                    
                } else {
                    //if it's been less than a day, let them know they've checked in too recently
                    JSSAlertView().show(self, title: "Sorry", text : "You have already checked in to this location is the past 24 hours.", buttonText: "OK", color: UIColorFromHex(0xff3333, alpha: 1))
                    print("You've checked in within the last 24 hours")
                }
                
            }
        } else {
            //if they aren't within range, let them know they aren't close enough to check in
            JSSAlertView().show(self, title: "Sorry", text : "You are not close enough to check in.", buttonText: "OK", color: UIColorFromHex(0xff3333, alpha: 1))
            print("not close enough to check in")
        }
    }
    
    @IBAction func exit(sender: AnyObject) {
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    @IBAction func upvoteAction(sender: AnyObject) {
        upvoteButton.tag = 1
        registerVote(upvoteButton)
    }
    
    @IBAction func downvoteAction(sender: AnyObject) {
        downvoteButton.tag = -1
        registerVote(downvoteButton)
    }
    
    @IBAction func viewComments(sender: AnyObject) {
                self.performSegueWithIdentifier("viewComments", sender: sender.tag)
    }
    
    //end IBAction zone
    
//----------------------------------------------
    
    //func zone
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations[0]
        print("\(userLocation.coordinate.latitude) Degrees Latitude, \(userLocation.coordinate.longitude) Degrees Longitude")
        locationUpdated = true
    }
    
    func loadUIDetails() {
        
        detailView.backgroundColor = UIColor.clearColor()
        print(userID)
        let navBarBGImage = UIImage(named: "Navigation_Bar_Gold")
        navigationBar.setBackgroundImage(navBarBGImage, forBarMetrics: .Default)
        navigationBar.topItem!.title = imageTitle
        
        captionLabel.text = caption
        captionLabel.textColor = UIColor.whiteColor()
        userNameLabel.text = userName
        userNameLabel.textColor = UIColor.whiteColor()
        
        let vote : Vote = AWSService().loadVote(userID+"_"+imageID)
        if vote.voteValue == 1{
            upvoteButton.alpha = 0.5
        } else if vote.voteValue == -1{
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
    
    func registerVote(sender: UIButton)
    {
        let modifier = sender.tag
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let currentDate = NSDate()
        
        let vote : Vote = AWSService().loadVote(userID + "_" + imageID)
        
        //change vote status appropriately based on current vote state
        var change = 0
        if vote.voteValue == 0 {
            
            change = modifier
            //set all parameters in case it is a new vote
            vote.voteValue = modifier
            vote.voteID = userID + "_" + imageID
            vote.owner = userName
            vote.imageID = imageID
            
            if modifier == 1 {
                upvoteButton.alpha = 0.5
            } else if modifier == -1 {
                downvoteButton.alpha = 0.5
            }
            
        } else if vote.voteValue == 1 {
            
            if modifier == 1 {
                change = -1
                upvoteButton.alpha = 1.0
                downvoteButton.alpha = 1.0
            } else if modifier == -1 {
                change = -2
                upvoteButton.alpha = 0.5
                downvoteButton.alpha = 1.0
            }
            vote.voteValue += change
            
        } else if vote.voteValue == -1 {
            
            if modifier == 1 {
                change = 2
                upvoteButton.alpha = 0.5
                downvoteButton.alpha = 1.0
            } else if modifier == -1 {
                change = 1
                upvoteButton.alpha = 1.0
                downvoteButton.alpha = 1.0
            }
            vote.voteValue += change
            
            
        } else {
            print("vote.voteValue is not a valid number")
        }
        //update time of vote regardless of initial state
        vote.timeVoted = dateFormatter.stringFromDate(currentDate)
        
        AWSService().save(vote)
        
        //update owner of images score
        self.imageData.totalScore += change
        AWSService().loadUser(self.imageData.userID,completion: {(result)->Void in
            self.user = result
        })

        user.score += change
        AWSService().save(user)
        AWSService().save(self.imageData)
        
        //update label with correct score
        upvotesLabel.text = String(self.imageData.totalScore)
        
    }
    
    func calculateHotColdScore(){
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        //factors for decaying function
        let a = -1000.0
        let flatnessFactor = 3.0
        
        //retrieve all votes for image
        hotColdScore = 0
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.filterExpression = "imageID = "+imageID
        dynamoDBObjectMapper.query(Vote.self, expression: queryExpression).continueWithBlock({(task: AWSTask) -> AnyObject in
            if (task.error != nil) {
                print("The request failed. Error: [\(task.error)]")
            }
            if (task.exception != nil) {
                print("The request failed. Exception: [\(task.exception)]")
            }
            if (task.result != nil) {
                let output : AWSDynamoDBPaginatedOutput = task.result as! AWSDynamoDBPaginatedOutput
                //for each vote, calculate the decayed value and add it to the hotColdScore
                for vote  in output.items {
                    let vote : Vote = vote as! Vote
                    let timeVote = dateFormatter.dateFromString(vote.timeVoted)!
                    let hoursSinceVote = Double(NSDate().timeIntervalSinceDate(timeVote))/3600.0
                    let decayedValue = Double(vote.voteValue)*max(a*pow(hoursSinceVote,flatnessFactor)+1, 0)
                    self.hotColdScore += decayedValue
                }
                print("The request succeeded. HotColdScore = " + String(self.hotColdScore))
                return self.hotColdScore
            }
            return self.hotColdScore
        })

        
        self.imageData.hotColdScore = self.hotColdScore
        AWSService().save(self.imageData)
    }
    
    //end func zone
    
//----------------------------------------------
    
    //override func zone
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AWSService().loadImage(imageID, completion: {(result)->Void in
            self.imageData = result
        })

        //fetch check in
        AWSService().loadCheckIn(self.userID + "_" + self.imageData.placeTitle, completion: {(result)->Void in
            self.checkInRequest = result
        })
        loadUIDetails()
        loadImageDetail()
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "viewComments" {
            if let destinationVC = segue.destinationViewController as? CommentController{
                
                destinationVC.imageID = imageID
                destinationVC.userNameOP = userNameOP
                destinationVC.userName = userName
            }
        }
    }
    
    //end override func zone
//----------------------------------------------
    
}