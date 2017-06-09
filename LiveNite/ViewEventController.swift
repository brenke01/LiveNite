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
    var imageUtil = ImageUtil()
    var playerLayer = AVPlayerLayer()
    var player = AVPlayer()
    var playerAdded = false
    @IBOutlet weak var tableView: UITableView!
    var scrollViewContentHeight = 0 as CGFloat
    let screenHeight = UIScreen.main.bounds.height
    override func viewDidLoad(){
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: nil, using: { (_) in
            DispatchQueue.main.async {
                self.player.seek(to: kCMTimeZero)
                
                self.playerLayer.player?.play()
            }
        })
        self.navigationController?.navigationBar.tintColor = UIColor.white
        //self.navigationController?.navigationBar.topItem?.title = selectedEvent?.eventTitle
        let checkInButton = UIBarButtonItem(image: UIImage(named: "checkInButton"), style: .plain, target: self, action: #selector(ViewEventController.checkIn))
        navigationItem.rightBarButtonItem = checkInButton
        self.refreshControl.tintColor = UIColor.white
        
        self.tableView.addSubview(self.refreshControl)
        loadEventDetails()

        
    }
    
    func back(_ sender: UIBarButtonItem){
        playerLayer.player?.pause()
        player.pause()
        playerLayer.removeFromSuperlayer()
        playerLayer.player = nil
        _ = navigationController?.popViewController(animated: true)
    }
    
    func loadEventDetails(){

        AWSService().loadCheckIn((self.selectedEvent?.eventID)!, completion: {(result)->Void in
            self.checkInRequest = result
            
            
        })
        
        
        getCheckIns(completion: {(result)->Void in
            self.checkInArray = result
            let eventTimeFormatter = DateFormatter()
            eventTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            let currentDate = Date()
            var eventStart = eventTimeFormatter.date(from: (self.selectedEvent?.eventStartTime)!)
            var newCheckIns = [CheckIn]()
            if (eventStart! < currentDate){
                for c in self.checkInArray{
                    if (c.goingToEvent){
                        newCheckIns.append(c)
                    }
                }
                self.checkInArray = newCheckIns
            }else{
                for c in self.checkInArray{
                    if (!c.goingToEvent){
                        newCheckIns.append(c)
                    }
                }
                self.checkInArray = newCheckIns
            }
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
            let eventTimeFormatter = DateFormatter()
            eventTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            let currentDate = Date()
            var eventStart = eventTimeFormatter.date(from: (selectedEvent?.eventStartTime)!)
            var eventEnd = eventTimeFormatter.date(from: (selectedEvent?.eventEndTime)!)

            if (eventStart! > currentDate){
                if (self.checkInRequest?.userID == ""){
                    let checkIn : CheckIn = CheckIn()
                    checkIn.checkInID = (self.selectedEvent?.eventID)!
                    checkIn.checkInTime = dateFormatter.string(from: currentDate)
                    checkIn.placeTitle = (self.selectedEvent?.placeTitle)!
                    checkIn.gender = self.user!.gender
                    checkIn.userID = (self.user?.userID)!
                    checkIn.imageID = (self.selectedEvent?.eventID)!
                    checkIn.goingToEvent = true
                    AWSService().save(checkIn)
                    SCLAlertView().showSuccess("Congrats", subTitle: "You are going to this event!")
                    AWSService().loadCheckIn((self.selectedEvent?.eventID)!, completion: {(result)->Void in
                        self.checkInRequest = result
                        
                        
                    })
                    
                    
                    getCheckIns(completion: {(result)->Void in
                        self.checkInArray = result
                        
                        self.tableView.reloadData()
                    })
                }else{
                    SCLAlertView().showError("Sorry", subTitle: "You are already going to this event!")
                }
                
            }else if (eventEnd! < currentDate){
                SCLAlertView().showError("Sorry", subTitle: "This event has ended!")

            
            }else{
    
            
            //fetch image data for post
                
                
                //determine distance between user and place and set maxAllowableDistance
                let imagePlaceLocation = CLLocation(latitude: (self.selectedEvent?.eventLat)!, longitude: (self.selectedEvent!.eventLong))
                let distanceBetweenUserAndPlace : CLLocationDistance = imagePlaceLocation.distance(from: userLocation)
                let maxAllowableDistance : CLLocationDistance = 100
                var notifUUID =  UUID().uuidString
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
                        checkIn.goingToEvent = false
                        AWSService().save(checkIn)
                        var notification = Notification()
                        notification?.notificationID = notifUUID
                        notification?.userName = (self.user?.userName)!
                        notification?.ownerName = (self.selectedEvent?.ownerName)!
                        var date = Date()
                        notification?.actionTime = String(describing: date)
                        notification?.imageID = (self.selectedEvent?.eventID)!
                        notification?.open = true
                        notification?.type = "checkIn"
                        var dayComponent = DateComponents()
                        dayComponent.day = 1
                        var cal = Calendar.current
                        var nextDay = cal.date(byAdding: dayComponent, to: date)
                        var nextDayEpoch = UInt64(floor((nextDay?.timeIntervalSince1970)!))
                        notification?.expirationDate = Int(nextDayEpoch)
                        AWSService().save(notification!)
                        
                        //Award user points
                        print("userID: \(userID)")
                        
                        self.user?.score += 5
                        AWSService().save(user!)
                        print("Score: \(user?.score)")
                        SCLAlertView().showSuccess("Congrats", subTitle: "You have checked in and earned 5 points!")
                        AWSService().loadCheckIn((self.selectedEvent?.eventID)!, completion: {(result)->Void in
                            self.checkInRequest = result
                            
                            
                        })
                        
                        
                        getCheckIns(completion: {(result)->Void in
                            self.checkInArray = result
                            
                            self.tableView.reloadData()
                        })
                        
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
                            var notification = Notification()
                            notification?.notificationID = notifUUID
                            notification?.userName = (self.user?.userName)!
                            notification?.ownerName = (self.selectedEvent?.ownerName)!
                            var date = Date()
                            notification?.actionTime = String(describing: date)
                            notification?.imageID = (self.selectedEvent?.eventID)!
                            notification?.open = true
                            notification?.type = "checkIn"
                            var dayComponent = DateComponents()
                            dayComponent.day = 1
                            var cal = Calendar.current
                            var nextDay = cal.date(byAdding: dayComponent, to: date)
                            var nextDayEpoch = UInt64(floor((nextDay?.timeIntervalSince1970)!))
                            notification?.expirationDate = Int(nextDayEpoch)
                            AWSService().save(notification!)
                            
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
        manager.stopUpdatingLocation()
    }
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        return refreshControl
    }()
    
    func handleRefresh(_ refreshControl: UIRefreshControl){

        loadEventDetails()
        
        
        
    }
    
    //
    func loadUIDetails() {
        let cell:EventImgCell = self.tableView.dequeueReusableCell(withIdentifier: "eventImgCell")! as! EventImgCell
        
        loadComments(completion: {(result)->Void in
            self.commentArray = result as! [Comment]
             self.commentArray.sort {$0.timePosted > $1.timePosted}
            self.refreshControl.endRefreshing()
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
        if ((self.selectedEvent?.isVideo)! && !self.playerAdded){
            self.playerAdded = true
            let url = URL(string: "https://s3.amazonaws.com/liveniteimages/" + (selectedEvent?.url)!)
            player = AVPlayer(url: url!)
            
            playerLayer = AVPlayerLayer(player: player)
            playerLayer.layoutSublayers()
            
            playerLayer.frame = cell.imgView.frame
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            cell.layer.addSublayer(playerLayer)
            self.playerLayer.player?.play()
            //perform play pause toggle on didselectrowatindexpath
            
        }else{
            
            cell.imgView.image = self.img
            
            
            
        }
        cell.upvotesLabel.text = String(describing: self.selectedEvent?.totalScore)
        cell.upvotesLabel.textColor = UIColor.white
        calculateHotColdScore({(result)->Void in
            var score = result[0] as Double
            
            self.tableView.reloadData()
        })
        
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
        queryExpression.expressionAttributeValues = [":val": self.selectedEvent?.ownerName]
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
        
        //navigationBar.topItem!.title = self.selectedEvent?.placeTitle
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
            vote?.ownerName = (self.user?.userID)!
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
        vote?.ownerName = (self.selectedEvent?.ownerName)!
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
    
    func calculateHotColdScore(_ completion:@escaping (_ result:[Double])->Void)->[Double]{
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        //factors for decaying function
        let a = -100.0
        let flatnessFactor = 3.0
        
        //retrieve all votes for image
        hotColdScore = 0
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.indexName = "imageID-ownerName-index"
        queryExpression.keyConditionExpression = "imageID = :imageID"
        queryExpression.expressionAttributeValues = [":imageID": self.selectedEvent?.eventID]
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
                self.selectedEvent?.hotColdScore = self.hotColdScore
                AWSService().save(self.selectedEvent!)
                
                completion([self.hotColdScore])
                
                return self.hotColdScore as Double as AnyObject
                
            }
            return self.hotColdScore as Double as AnyObject
        })
        
        
        self.selectedEvent?.hotColdScore = self.hotColdScore
        return [self.hotColdScore as Double]
    }
    
    //end func zone
    
    //----------------------------------------------
    
    //override func zone
    @IBOutlet weak var commentHeightRestraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var commentLabel: UILabel!
    
    @IBOutlet weak var commentUserNameLabel: UILabel!
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        var titleView = UIView(frame: CGRect(x: 0, y: 0, width: 180, height: 32))
        titleView.backgroundColor = UIColor.clear
       var eventTitleView = UILabel(frame: CGRect(x: 0, y: 0, width: 180, height: 16))
        var placeTitleView = UILabel(frame: CGRect(x: 0, y: 16, width: 180, height: 16))
        eventTitleView.textColor = UIColor.white
        eventTitleView.text = self.selectedEvent?.eventTitle
       eventTitleView.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
        eventTitleView.textAlignment = NSTextAlignment.center
        placeTitleView.textColor = UIColor.white
        placeTitleView.text = self.selectedEvent?.placeTitle
        placeTitleView.font = UIFont(name: "HelveticaNeue-Bold", size: 14)
        placeTitleView.textAlignment = NSTextAlignment.center
        eventTitleView.adjustsFontSizeToFitWidth = true
        eventTitleView.minimumScaleFactor = 0.2
        placeTitleView.adjustsFontSizeToFitWidth = true
        placeTitleView.minimumScaleFactor = 0.2
        
        titleView.addSubview(eventTitleView)
        titleView.addSubview(placeTitleView)
        
        
        self.navigationItem.titleView = titleView
        var barButton = UIBarButtonItem(title: " ", style: .plain, target: self, action: #selector(self.back(_:)))
        barButton.title = " "
        barButton.image = UIImage(named: "backBtn")
        
        self.navigationItem.leftBarButtonItem = barButton
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
        var border = CALayer()
        var width = CGFloat(1.0)
        if (indexPath.row == 0){
            let cell:EventImgCell = self.tableView.dequeueReusableCell(withIdentifier: "eventImgCell")! as! EventImgCell
            //navBar.topItem?.title = self.selectedEvent?.eventTitle
            //calculateHotColdScore()
            cell.upvotesLabel.text = String(self.selectedEvent!.totalScore)
            //Needs styling
            tableView.backgroundColor = UIColor.clear
            tableView.isOpaque = false
            if (self.selectedEvent?.ownerID != self.user?.userID){
                cell.optionsButton.isHidden = true
            }
            if ((self.selectedEvent?.isVideo)!){
                
                playerLayer.layoutSublayers()
                playerLayer.frame = cell.imgView.frame
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                cell.layer.addSublayer(playerLayer)
                
            }else{
                cell.imgView.image = self.img
                
            }
            cell.backgroundColor = UIColor.clear
            cell.upvotesLabel.textColor = UIColor.white
            cell.captionLabel.textColor = UIColor.white
            cell.userNameLabel.textColor = UIColor.white
            cell.genderBar.layer.cornerRadius = 3
            cell.genderBar.clipsToBounds = true
            cell.genderBar.layer.masksToBounds = true

            cell.captionLabel.text = self.selectedEvent?.information
            cell.userNameLabel.text = self.selectedEvent?.ownerName
            //cell.upvoteButton.backgroundColor = UIColor.white
            cell.downvoteButton.isHidden = false
            cell.upvoteButton.isHidden = false
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.hotColdLabel.text = String(floor((self.selectedEvent?.hotColdScore)! * 100)) + "%"
            if (self.hotColdScore > 0.75){
                cell.hotColdLabel.textColor = UIColor.green
            }else if (self.hotColdScore <= 0.75 && self.hotColdScore >= 0.25){
                cell.hotColdLabel.textColor = UIColor.yellow
            }else if (self.hotColdScore < 0.25 && self.hotColdScore > 0){
                cell.hotColdLabel.textColor = UIColor.red
            }else{
                cell.hotColdLabel.textColor = UIColor.white
                
            }
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
             let now = Date()
            let dateFormatter = DateFormatter()
            let localeStr = "us"
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            dateFormatter.locale = Locale.current
            let eventEndDate = dateFormatter.date(from: (self.selectedEvent?.eventEndTime)!)
            if (eventEndDate! < now){
                var interval = now.timeIntervalSince(eventEndDate!)
                var intervalStr = ""
                interval = interval / 3600
                if (interval < 1){
                    interval = interval * 60
                    let intervalInt = Int(interval)
                    if (intervalInt == 0){
                        intervalStr = "Just ended"
                        
                    }else{
                        intervalStr = String(intervalInt) + "m"
                        
                        
                    }
                }else{
                    var intervalInt = Int(interval)
                    if (intervalInt > 23){
                        intervalInt = (intervalInt / 24)
                        if (intervalInt > 364){
                            intervalStr = String(intervalInt / 365) + "y"
                            
                        }else{
                            intervalStr = String(intervalInt) + "d"
                            
                        }
                    }else{
                        intervalStr = String(intervalInt) + "h"
                        
                    }
                }
                
                cell.eventTimeLabel.text = intervalStr
            }else{
                 cell.eventTimeLabel.text = formatEventTime(startTime: (self.selectedEvent?.eventStartTime)!)
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
                if (intervalInt == 0){
                    intervalStr = "now"
                    
                }else{
                    intervalStr = String(intervalInt) + "m"

                    
                }
            }else{
                var intervalInt = Int(interval)
                if (intervalInt > 23){
                    intervalInt = (intervalInt / 24)
                    if (intervalInt > 364){
                        intervalStr = String(intervalInt / 365) + "y"
                        
                    }else{
                        intervalStr = String(intervalInt) + "d"
                        
                    }
                }else{
                    intervalStr = String(intervalInt) + "h"
                    
                }
            }
            
            
            cell.timeLabel.text = intervalStr
            cell.timeLabel.textColor = UIColor.white
            cell.userNameLabel.text = self.commentArray[indexPath.row - 1].ownerName
            
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
            
            border.borderColor = UIColor.white.cgColor
            border.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1)
            border.borderWidth = width
            tableView.layer.addSublayer(border)
            return cell
        }
        
        
        
        
    }
    
    func formatEventTime(startTime: String) -> String {
        let dateFormatter = DateFormatter()
        let localeStr = "us"
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        dateFormatter.locale = Locale.current
        let eventDate = dateFormatter.date(from: startTime)
        let todayDate = dateFormatter.date(from: String(describing: Date()))
        let cal = NSCalendar(calendarIdentifier: NSCalendar.Identifier(rawValue: NSGregorianCalendar))!
        let comp = cal.components(.weekday, from: eventDate!)
        let todayComp = cal.components(.weekday, from: todayDate!)
        let todayDay = todayComp.weekday
        let weekDay = comp.weekday
        var dayName = ""
        if (weekDay == todayDay){
            dayName = "Today"
        }else if (weekDay! == todayDay! + 1){
            dayName = "Tomorrow"
        }else if (weekDay == 1){
            dayName = "Sunday"
        }else if (weekDay == 2){
            dayName = "Monday"
        }else if (weekDay == 3){
            dayName = "Tuesday"
        }else if (weekDay == 4){
            dayName = "Wednesday"
        }else if (weekDay == 5){
            dayName = "Thursday"
        }else if (weekDay == 6){
            dayName = "Friday"
        }else if (weekDay == 7){
            dayName = "Saturday"
        }
        var partOfDay = "AM"
        var hour = cal.component(.hour, from: eventDate!)
        if (hour >= 12){
            hour = 12 - (24 - hour)
            partOfDay = "PM"
        }
        var formattedEventDate = dayName + " at " + String(hour) + partOfDay
        return formattedEventDate
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
    
    func deleteEvent(){
        AWSService().deleteItem(self.selectedEvent!)
        
        _ = navigationController?.popViewController(animated: true)
        imageUtil.imageDeleted = true
    }
    
    @IBAction func loadImageOptions(){
        let alertController = UIAlertController(title: nil, message: "Please select an action", preferredStyle: .actionSheet)
        //self.navigationItem.leftBarButtonItem?.title = ""
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
            // ...
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(cancelAction)
        
        let destroyAction = UIAlertAction(title: "Delete", style: .destructive) { action in
            self.deleteEvent()
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(destroyAction)
        var barButton = UIBarButtonItem(title: " ", style: .plain, target: self, action: #selector(self.back(_:)))
        barButton.title = " "
        barButton.image = UIImage(named: "backBtn")
        
        self.navigationItem.leftBarButtonItem = barButton
        self.present(alertController, animated: true) {
            // ...
        }
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
    @IBOutlet weak var optionsButton : UIButton!

    @IBOutlet weak var eventTimeLabel: UILabel!
    @IBOutlet weak var femaleLabel: UILabel!
    @IBOutlet weak var maleLabel: UILabel!
    @IBOutlet weak var hotColdLabel: UILabel!
    
}

class EventCommentTableViewCell: UITableViewCell{
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var commentHeight: NSLayoutConstraint!
    
}
