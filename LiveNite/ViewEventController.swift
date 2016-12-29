//
//  ViewEventController.swift
//  LiveNite
//
//  Created by Kevin  on 11/7/16.
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
import AWSDynamoDB
import AWSS3
import SCLAlertView

class ViewEventController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate{
    
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var eventImg: UIImageView!
    @IBOutlet var navigationBar: UINavigationBar!

    var selectedEvent = Event()
    var img = UIImage()
    var user = User()
    var locationManager = CLLocationManager()
    var userLocation = CLLocation()
    var locationUpdated = false
    var userID = ""
    var userNameOP = ""
    var imageID = ""
    var imageUpvotes = 0
    var imageTitle =  ""
    var caption = ""
    var userName = ""
    var hotColdScore = 0.0
    var checkInRequest = CheckIn()
    var vote = Vote()
    var commentInfoArray : [[String:String]] = []
    var commentArray = [Comment]()
    var checkInArray = [CheckIn]()
    var hasUpvoted = false
    var hasDownvoted = false
    @IBOutlet weak var tableView: UITableView!
    var scrollViewContentHeight = 0 as CGFloat
    let screenHeight = UIScreen.main.bounds.height
    override func viewDidLoad(){
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.topItem?.title = selectedEvent?.eventTitle
        let checkInButton = UIBarButtonItem(image: UIImage(named: "checkInButton"), style: .plain, target: self, action: #selector(ViewEventController.checkIn))
        navigationItem.rightBarButtonItem = checkInButton
        

        

        AWSService().loadCheckIn((self.selectedEvent?.eventID)!, completion: {(result)->Void in
            self.checkInRequest = result
        })
        
        
        getCheckIns(completion: {(result)->Void in
            self.checkInArray = result
            self.tableView.reloadData()
        })
        
        
        
        loadImageDetail()
        loadUIDetails()
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
    }
    
    @IBAction func exit(_ sender: AnyObject) {
        self.dismiss(animated: false, completion: nil)

    }

    
    //end var zone
    
    //----------------------------------------------
    
    //IBAction zone
    
        @IBAction func checkIn(_ sender: AnyObject) {
    
            //create date formatter to allow conversion of dates to string and vice versa throughout function
            //set current date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            let currentDate = Date()
            
            //fetch image data for post
            
            
            //determine distance between user and place and set maxAllowableDistance
            let imagePlaceLocation = CLLocation(latitude: (self.selectedEvent?.eventLat)!, longitude: (self.selectedEvent!.eventLong))
            let distanceBetweenUserAndPlace : CLLocationDistance = imagePlaceLocation.distance(from: userLocation)
            let maxAllowableDistance : CLLocationDistance = 2500
            
            //if within range, check if they've checked in recently
            if distanceBetweenUserAndPlace < maxAllowableDistance {
                
                
                
                //If the userID was not set, then the checkInRequest doesn't exist in the db and it is a new check in
                if (self.checkInRequest?.userID == ""){
                    
                    //Make new check in in table
                    let checkIn : CheckIn = CheckIn()
                    checkIn.checkInID = (self.selectedEvent?.eventID)!
                    checkIn.checkInTime = dateFormatter.string(from: currentDate)
                    checkIn.placeTitle = (self.selectedEvent?.placeTitle)!
                    checkIn.gender = self.user!.gender
                    checkIn.userID = (self.user?.userID)!
                    checkIn.imageID = (self.selectedEvent?.eventID)!
                    AWSService().save(checkIn)
                    
                    //Award user points
                    print("userID: \(userID)")
                    
                    self.user?.score += 5
                    AWSService().save(user!)
                    print("Score: \(user?.score)")
                    SCLAlertView().showSuccess("Congrats", subTitle: "You have checked in and earned 5 points!")
                    
                } else {
                    //if it did set the userID, they've checked in there before so we need to see how long it's been
                    
                    //get last check in date
                    let lastCheckIn : Date = dateFormatter.date(from: self.checkInRequest!.checkInTime)!
                    
                    //get the difference in date components
                    let diffDateComponents = (Calendar.current as NSCalendar).components([NSCalendar.Unit.year, NSCalendar.Unit.month, NSCalendar.Unit.day, NSCalendar.Unit.hour, NSCalendar.Unit.minute, NSCalendar.Unit.second], from: lastCheckIn, to: currentDate, options: NSCalendar.Options.init(rawValue: 0))
                    
                    print("The difference between dates is: \(diffDateComponents.year) years, \(diffDateComponents.month) months, \(diffDateComponents.day) days, \(diffDateComponents.hour) hours, \(diffDateComponents.minute) minutes, \(diffDateComponents.second) seconds")
                    
                    //if it has been more than a day award the user points and update the check in time
                    if (diffDateComponents.year! > 0 || diffDateComponents.month! > 0 || diffDateComponents.day! > 0){
                        print("It's been a while")
                        
                        //Award user points
                        print("userID: \(userID)")
                        SCLAlertView().showSuccess("Congrats", subTitle: "You have checked in and earned 5 points!")
                        
                        user?.score += 5
                        AWSService().save(user!)
                        print("Score: \(user?.score)")
                        
                        //Update check in date
                        self.checkInRequest?.checkInTime = dateFormatter.string(from: currentDate)
                        AWSService().save(self.checkInRequest!)
                        
                        //Notify user of successful check in
                        
                    } else {
                        //if it's been less than a day, let them know they've checked in too recently
                        print("You've checked in within the last 24 hours")
                        SCLAlertView().showError("Sorry", subTitle: "You have already checked in within the last 24 hours")
                    }
                    
                }
            } else {
                //if they aren't within range, let them know they aren't close enough to check in
                SCLAlertView().showInfo("Sorry", subTitle: "You are not close enough to check in")
                print("not close enough to check in")
            }

        }
    
    @IBAction func upvoteAction(_ sender: AnyObject) {
        let cell:EventImgCell = self.tableView.dequeueReusableCell(withIdentifier: "eventImgCell")! as! EventImgCell
                cell.upvoteButton.tag = 1
                registerVote(cell.upvoteButton)
    }
    
    @IBAction func downvoteAction(_ sender: AnyObject) {
        let cell:EventImgCell = self.tableView.dequeueReusableCell(withIdentifier: "eventImgCell")! as! EventImgCell
                cell.downvoteButton.tag = -1
                registerVote(cell.downvoteButton)
    }
    
    @IBAction func viewComments(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "viewComments", sender: sender.tag)
    }
    
    //end IBAction zone
    
    //----------------------------------------------
    
    //func zone
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations[0]
        print("\(userLocation.coordinate.latitude) Degrees Latitude, \(userLocation.coordinate.longitude) Degrees Longitude")
        locationUpdated = true
    }
    //
    func loadUIDetails() {
        let cell:EventImgCell = self.tableView.dequeueReusableCell(withIdentifier: "eventImgCell")! as! EventImgCell
        
        loadComments(completion: {(result)->Void in
            self.commentArray = result as! [Comment]
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
                
            })
            
        })
        
        AWSService().loadVote((self.user?.userID)! + "_" + (self.selectedEvent?.eventID)!,completion: {(result)->Void in

            self.vote = result
            if self.vote?.voteValue == 1{
                self.hasUpvoted = true
                self.hasDownvoted = false
            } else if self.vote?.voteValue == -1{
                
               self.hasDownvoted = true
                self.hasUpvoted = false
            }
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
                
            })
        })
        
        
    }
    
    
    
    
    func loadImageDetail(){
        let cell:EventImgCell = self.tableView.dequeueReusableCell(withIdentifier: "eventImgCell")! as! EventImgCell
        //Query to check if user can vote
//        hasVoted({(result)->Void in
//            var voteArr = result
//            if (voteArr.count > 0){
//                let vote = voteArr[0]
//                var voteValue = vote.voteValue
//                
//            }
//            
//        })
        cell.imgView.image = self.img
        //calculateHotColdScore()
        cell.upvotesLabel.text = String(describing: self.selectedEvent?.totalScore)
        //Needs styling
        cell.upvotesLabel.textColor = UIColor.white
        
    }
    
    func hasVoted(_ completion:@escaping (_ result:[Vote])->Void)->[Vote]{
        var votesArray = [Vote]()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.indexName = "imageID-owner-index"
        queryExpression.hashKeyAttribute = "imageID"
        queryExpression.hashKeyValues = self.selectedEvent?.eventID
        queryExpression.rangeKeyConditionExpression = "owner = :val"
        queryExpression.filterExpression = "placeTitle = :placeTitle"
        queryExpression.expressionAttributeValues = [":val": self.selectedEvent?.owner]
        dynamoDBObjectMapper.query(Vote.self, expression: queryExpression).continue({(task: AWSTask) -> AnyObject in
            if (task.error != nil) {
                print("The request failed. Error: [\(task.error)]")
            }
            if (task.exception != nil) {
                print("The request failed. Exception: [\(task.exception)]")
            }
            if (task.result != nil) {
                let output : AWSDynamoDBPaginatedOutput = (task.result!)
                for vote  in output.items {
                    let vote : Vote = vote as! Vote
                    votesArray.append(vote)
                }
                completion(votesArray)
            }
            return votesArray as AnyObject
        })
        return votesArray
        
    }
    
    func imageData_DisplayToUI()
    {
        
        navigationBar.topItem!.title = self.selectedEvent?.placeTitle
    }
    
    func registerVote(_ sender: UIButton)
    {
        let cell:EventImgCell = self.tableView.dequeueReusableCell(withIdentifier: "eventImgCell")! as! EventImgCell
        
        let modifier = sender.tag
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let currentDate = Date()
        
        //change vote status appropriately based on current vote state
        var change = 0
        if vote?.voteValue == 0 {
            
            change = modifier
            //set all parameters in case it is a new vote
            vote?.voteValue = modifier
            vote?.voteID = (self.user?.userID)! + "_" + (self.selectedEvent?.eventID)!
            vote?.owner = (self.user?.userID)!
            vote?.imageID = (self.selectedEvent?.eventID)!
            if modifier == 1 {
                self.hasUpvoted = true
                self.hasDownvoted = false
            } else if modifier == -1 {
                self.hasDownvoted = true
                self.hasUpvoted = false
            }
            
        } else if vote?.voteValue == 1 {
            
            if modifier == -1 {
                change = -2
                self.hasDownvoted = true
                self.hasUpvoted = false
            }
            vote?.voteValue += change
            
        } else if vote?.voteValue == -1 {
            
            if modifier == 1 {
                change = 2
                self.hasUpvoted = true
                self.hasDownvoted = false
            }
            vote?.voteValue += change
            
            
        } else {
            print("vote.voteValue is not a valid number")
        }
        //update time of vote regardless of initial state
        vote?.timeVoted = dateFormatter.string(from: currentDate)
        vote?.owner = (self.selectedEvent?.owner)!
        AWSService().save(vote!)
        
        //update owner of images score
        self.selectedEvent?.totalScore += change
        print("User ID = " + self.userID)
        self.user?.score += change
        AWSService().save(self.user!)
        AWSService().save(self.selectedEvent!)
        
        //update label with correct score
        cell.upvotesLabel.text = String(describing: self.selectedEvent?.totalScore)
        self.tableView.reloadData()
        
        
        
        
    }
    
    func calculateHotColdScore(){
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        //factors for decaying function
        let a = -1000.0
        let flatnessFactor = 3.0
        
        //retrieve all votes for image
        hotColdScore = 0
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.filterExpression = "imageID = "+imageID
        dynamoDBObjectMapper.query(Vote.self, expression: queryExpression).continue({(task: AWSTask) -> AnyObject in
            if (task.error != nil) {
                print("The request failed. Error: [\(task.error)]")
            }
            if (task.exception != nil) {
                print("The request failed. Exception: [\(task.exception)]")
            }
            if (task.result != nil) {
                let output : AWSDynamoDBPaginatedOutput = (task.result!)
                //for each vote, calculate the decayed value and add it to the hotColdScore
                for vote  in output.items {
                    let vote : Vote = vote as! Vote
                    let timeVote = dateFormatter.date(from: vote.timeVoted)!
                    let hoursSinceVote = Double(Date().timeIntervalSince(timeVote))/3600.0
                    let decayedValue = Double(vote.voteValue)*max(a*pow(hoursSinceVote,flatnessFactor)+1, 0)
                    self.hotColdScore += decayedValue
                }
                print("The request succeeded. HotColdScore = " + String(self.hotColdScore))
                return self.hotColdScore as AnyObject
            }
            return self.hotColdScore as AnyObject
        })
        
        
        self.selectedEvent?.hotColdScore = self.hotColdScore
        AWSService().save(self.selectedEvent!)
    }
    
    //end func zone
    
    //----------------------------------------------
    
    //override func zone
    @IBOutlet weak var commentHeightRestraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var commentUserNameLabel: UILabel!
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "postEventComment" {
            if let destinationVC = segue.destination as? PostCommentController{
                destinationVC.event = self.selectedEvent
                
                destinationVC.user = self.user
           }
        }
    }
    
    //end override func zone
    //----------------------------------------------
    
    
    func numberOfSectionsinTableView(_ tableView: UITableView) -> Int{
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)-> Int{
        return self.commentArray.count + 1 
    }
    
    func loadComments(completion:@escaping ([Comment])->Void)-> [Comment]{
        
        var commentArray = [Comment]()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.hashKeyAttribute = "commentID"
        queryExpression.indexName = "imageID-index"
        queryExpression.hashKeyAttribute = "imageID"
        queryExpression.hashKeyValues = self.selectedEvent?.eventID
        dynamoDBObjectMapper.query(Comment.self, expression: queryExpression).continue({(task: AWSTask) -> AnyObject in
            if (task.error != nil) {
                print("The request failed. Error: [\(task.error)]")
            }
            if (task.exception != nil) {
                print("The request failed. Exception: [\(task.exception)]")
            }
            if (task.result != nil) {
                let output : AWSDynamoDBPaginatedOutput = task.result!
                for comment  in output.items {
                    let comment : Comment = comment as! Comment
                    commentArray.append(comment)
                }
                completion(commentArray)
                return commentArray as AnyObject
            }
            return commentArray as AnyObject
        })
        
        return commentArray
        
    }
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        
        return UITableViewAutomaticDimension
        
        
        
        
    }
    
    func tableView(_ tableView: UITableView, willDisplayCell indexPath: IndexPath) {
        if (indexPath.row == tableView.indexPathsForVisibleRows?.last?.row){
            tableView.reloadData()
        }
    }
    
    //
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.row == 0){
            return 460
        }else{
            return 72
        }
        
    }
    
    
    
    
    func tableView(_ tableView:UITableView, cellForRowAt
        indexPath: IndexPath)-> UITableViewCell{
        
        //
        if (indexPath.row == 0){
            let cell:EventImgCell = self.tableView.dequeueReusableCell(withIdentifier: "eventImgCell")! as! EventImgCell
            navBar.topItem?.title = self.selectedEvent?.eventTitle
            cell.imgView.image = self.img
            //calculateHotColdScore()
            cell.upvotesLabel.text = String(self.selectedEvent!.totalScore)
            //Needs styling
            tableView.backgroundColor = UIColor.clear
            tableView.isOpaque = false
            cell.backgroundColor = UIColor.clear
            cell.upvotesLabel.textColor = UIColor.white
            cell.captionLabel.textColor = UIColor.white
            cell.userNameLabel.textColor = UIColor.white
            cell.captionLabel.text = self.selectedEvent?.information
            cell.userNameLabel.text = self.selectedEvent?.owner
            //cell.upvoteButton.backgroundColor = UIColor.white
            cell.downvoteButton.isHidden = false
            cell.upvoteButton.isHidden = false
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            if (self.hasUpvoted){
                cell.upvoteButton.alpha = 0.5
            }else{
                cell.upvoteButton.alpha = 1.0
            }
            if (self.hasDownvoted){
                cell.downvoteButton.alpha = 0.5
            }else{
                cell.downvoteButton.alpha = 1.0
            }
            var maleCount = 0
            var femaleCount = 0
            print("Check in Bar width")
            print(cell.genderBar.bounds.width)
            print(cell.genderBar.bounds.height)
            cell.genderBar.backgroundColor = UIColor.darkGray
            if self.checkInArray.count > 0{
                for checkIn in self.checkInArray{
                    if checkIn.gender == "male"{
                        maleCount += 1
                    }else{
                        femaleCount += 1
                    }
                }
               
                



                
                
                
                
            }
            cell.maleLabel.text = String(maleCount)
            cell.femaleLabel.text = String(femaleCount)
            cell.maleLabel.textColor = UIColor.white
            cell.femaleLabel.textColor = UIColor.white

            return cell
        }else{
            let cell:EventCommentTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "eventComment")! as! EventCommentTableViewCell
            
            var commentArr = self.commentArray
            
            tableView.backgroundColor = UIColor.clear
            let border = CALayer()
            let width = CGFloat(1.0)
            
            
            let timePosted = commentArr[(indexPath as NSIndexPath).row - 1].timePosted
            
            let dateFormatter = DateFormatter()
            let localeStr = "us"
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            dateFormatter.locale = Locale(identifier: localeStr)
            let timePostedFormatted = dateFormatter.date(from: timePosted)
            let now = Date()
            var interval = now.timeIntervalSince(timePostedFormatted!)
            var intervalStr = ""
            interval = interval / 3600
            if (interval < 1){
                interval = interval * 60
                let intervalInt = Int(interval)
                intervalStr = String(intervalInt) + "m"
            }else{
                let intervalInt = Int(interval)
                intervalStr = String(intervalInt) + "h"
            }
            
            
            cell.timeLabel.text = intervalStr
            cell.timeLabel.textColor = UIColor.white
            cell.userNameLabel.text = self.commentArray[indexPath.row - 1].owner
            
            cell.commentLabel.text = self.commentArray[indexPath.row - 1].comment
            //        cell.commentLabel.numberOfLines = 0
            //        cell.commentLabel.lineBreakMode = .byWordWrapping
            //        cell.commentLabel.preferredMaxLayoutWidth = cell.commentLabel.bounds.width
            cell.commentLabel.textColor = UIColor.white
            //cell.layoutIfNeeded()
            cell.userNameLabel.textColor = UIColor.white
            border.borderColor = UIColor.white.cgColor
            border.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1)
            border.borderWidth = width
            tableView.layer.addSublayer(border)
            
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            //cell.addSubview(cell.timeLabel)
            //cell.addSubview(cell.commentLabel)
            //cell.addSubview(cell.commentUserNameLabel)
            tableView.isOpaque = false
            cell.backgroundColor = UIColor.clear
            cell.isOpaque = false
            cell.textLabel?.textColor = UIColor.white
            
            return cell
        }
        
        
        
        
    }
    
    @IBAction func postComment(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "postEventComment", sender: sender.tag)
    }
    
    func getCheckIns(completion:@escaping ([CheckIn])->Void)->[CheckIn]{
        
        var checkInArray = [CheckIn]()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.indexName = "imageID-index"
        queryExpression.hashKeyAttribute = "imageID"
        queryExpression.hashKeyValues = self.selectedEvent?.eventID
        
        
        
        dynamoDBObjectMapper.query(CheckIn.self, expression: queryExpression).continue({(task: AWSTask) -> AnyObject in
            if (task.error != nil) {
                print("The request failed. Error: [\(task.error)]")
            }
            if (task.exception != nil) {
                print("The request failed. Exception: [\(task.exception)]")
            }
            if (task.result != nil) {
                let output : AWSDynamoDBPaginatedOutput = task.result!
                for checkIn  in output.items {
                    let checkIn : CheckIn = checkIn as! CheckIn
                    checkInArray.append(checkIn)
                }
                completion(checkInArray)
                return checkInArray as AnyObject
                
            }
            return checkInArray as AnyObject
        })
        
        
        return checkInArray
        
    }
    
    @IBAction func unwind(toEvent unwindSegue: UIStoryboardSegue){
                    DispatchQueue.main.async(execute: {
        self.loadComments(completion: {(result)->Void in
            self.commentArray = result as! [Comment]
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
                
            })
            
        })
        })
    }
    

}

class EventImgCell: UITableViewCell{
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var upvotesLabel: UILabel!
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var genderBar : UIView!
    @IBOutlet var imgView: UIImageView!
    @IBOutlet var upvoteButton: UIButton!
    @IBOutlet var downvoteButton: UIButton!
    
    @IBOutlet weak var femaleLabel: UILabel!
    @IBOutlet weak var maleLabel: UILabel!
    
}

class EventCommentTableViewCell: UITableViewCell{
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var commentHeight: NSLayoutConstraint!
    
}
