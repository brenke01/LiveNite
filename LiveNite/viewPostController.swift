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
import AWSDynamoDB
import AWSS3
import SCLAlertView

class viewPostController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate,UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate{
    
    //IBOutlet zone


    //@IBOutlet var navigationBar: UINavigationBar!
    
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
    var imageObj = Image()
    var vote = Vote()
    var commentInfoArray : [[String:String]] = []
    var commentArray = [Comment]()
    @IBOutlet weak var tableView: UITableView!
    var scrollViewContentHeight = 0 as CGFloat
    let screenHeight = UIScreen.main.bounds.height
    
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
        let imagePlaceLocation = CLLocation(latitude: (self.imageObj?.placeLat)!, longitude: (self.imageObj?.placeLong)!)
        let distanceBetweenUserAndPlace : CLLocationDistance = imagePlaceLocation.distance(from: userLocation)
        let maxAllowableDistance : CLLocationDistance = 2500
        
        //if within range, check if they've checked in recently
        if distanceBetweenUserAndPlace < maxAllowableDistance {

            
            
            //If the userID was not set, then the checkInRequest doesn't exist in the db and it is a new check in
            if (self.checkInRequest?.userID == ""){
                
                //Make new check in in table
                let checkIn : CheckIn = CheckIn()
                checkIn.checkInID = (self.user?.userID)! + "_" + (self.imageObj?.placeTitle)!
                checkIn.checkInTime = dateFormatter.string(from: currentDate)
                checkIn.placeTitle = (self.imageObj?.placeTitle)!
                checkIn.userID = (self.user?.userID)!
                print(checkIn.checkInID)
                print(checkIn.checkInTime)
                print(checkIn.userID)
                print(checkIn.placeTitle)
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
                    AWSService().loadUser(self.userID,completion: {(result)->Void in
                        self.user = result
                    })

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
                }
                
            }
        } else {
            //if they aren't within range, let them know they aren't close enough to check in
            SCLAlertView().showInfo("Sorry", subTitle: "You are not close enough to check in")
            print("not close enough to check in")
        }
    }
    
    @IBAction func exit(_ sender: AnyObject) {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func upvoteAction(_ sender: AnyObject) {
//        let cell:MyCustomTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "MyCustomTableViewCell")! as! MyCustomTableViewCell
//        cell.upvoteButton.tag = 1
//        registerVote(cell.upvoteButton)
    }
    
    @IBAction func downvoteAction(_ sender: AnyObject) {
//        let cell:MyCustomTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "MyCustomTableViewCell")! as! MyCustomTableViewCell
//        cell.downvoteButton.tag = -1
//        registerVote(cell.downvoteButton)
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
        let cell:MyCustomTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "MyCustomTableViewCell")! as! MyCustomTableViewCell

        loadComments(completion: {(result)->Void in
            self.commentArray = result as! [Comment]
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()

            })
            
        })

        AWSService().loadVote(userID + "_" + imageID,completion: {(result)->Void in
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
                
            })
            self.vote = result
        if self.vote?.voteValue == 1{
            cell.upvoteButton.alpha = 0.5
        } else if self.vote?.voteValue == -1{
           cell.downvoteButton.alpha = 0.5
        }
        })
        
        
   }

    

    
    func loadImageDetail(){
        let cell:MyCustomTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "MyCustomTableViewCell")! as! MyCustomTableViewCell
        //Query to check if user can vote
        hasVoted({(result)->Void in
            var voteArr = result
            if (voteArr.count > 0){
               let vote = voteArr[0]
                var voteValue = vote.voteValue
                
            }

        })
        cell.imgView.image = self.imageTapped
        //calculateHotColdScore()
        cell.upvotesLabel.text = String(imageObj!.totalScore)
        //Needs styling
        cell.upvotesLabel.textColor = UIColor.white
        
    }
    
    func hasVoted(_ completion:@escaping (_ result:[Vote])->Void)->[Vote]{
        var votesArray = [Vote]()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.indexName = "imageID-owner-index"
        queryExpression.hashKeyAttribute = "imageID"
        queryExpression.hashKeyValues = self.imageObj?.imageID
        queryExpression.rangeKeyConditionExpression = "owner = :val"
        queryExpression.filterExpression = "placeTitle = :placeTitle"
        queryExpression.expressionAttributeValues = [":val": self.imageObj?.owner]
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
        //let cell:MyCustomTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "MyCustomTableViewCell")! as! MyCustomTableViewCell
        //cell.upvotesLabel.text = String(imageObj!.totalScore)

    self.navigationController?.navigationBar.topItem?.title = imageObj?.placeTitle
    }
    
    func registerVote(_ sender: UIButton)
    {
          let cell:MyCustomTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "MyCustomTableViewCell")! as! MyCustomTableViewCell
        
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
                vote?.voteID = self.userID + "_" + self.imageID
                vote?.owner = self.userID
                vote?.imageID = self.imageID
                if modifier == 1 {
                    cell.upvoteButton.alpha = 0.5
                } else if modifier == -1 {
                    cell.downvoteButton.alpha = 0.5
                }
                
            } else if vote?.voteValue == 1 {
                
                if modifier == 1 {
                    change = -1
                    cell.upvoteButton.alpha = 1.0
                    cell.downvoteButton.alpha = 1.0
                } else if modifier == -1 {
                    change = -2
                    cell.upvoteButton.alpha = 0.5
                    cell.downvoteButton.alpha = 1.0
                }
                vote?.voteValue += change
                
            } else if vote?.voteValue == -1 {
                
                if modifier == 1 {
                    change = 2
                    cell.upvoteButton.alpha = 0.5
                    cell.downvoteButton.alpha = 1.0
                } else if modifier == -1 {
                    change = 1
                    cell.upvoteButton.alpha = 1.0
                    cell.downvoteButton.alpha = 1.0
                }
                vote?.voteValue += change
                
                
            } else {
                print("vote.voteValue is not a valid number")
            }
            //update time of vote regardless of initial state
            vote?.timeVoted = dateFormatter.string(from: currentDate)
            vote?.owner = (self.imageObj?.owner)!
            AWSService().save(vote!)
            
            //update owner of images score
            self.imageData?.totalScore += change
            AWSService().loadUser((self.imageData?.userID)!,completion: {(result)->Void in
                self.user = result
            })
            print("User ID = " + self.userID)
            self.user?.score += change
            AWSService().save(self.user!)
            AWSService().save(self.imageData!)
            
            //update label with correct score
            cell.upvotesLabel.text = String(self.imageData!.totalScore)

        
        
        
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

        
        self.imageData?.hotColdScore = self.hotColdScore
        AWSService().save(self.imageData!)
    }
    
    //end func zone
    
//----------------------------------------------
    
    //override func zone
    @IBOutlet weak var commentHeightRestraint: NSLayoutConstraint!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        self.navigationController?.navigationBar.tintColor = UIColor.white
            self.navigationController?.navigationBar.topItem?.title = imageObj?.placeTitle
        
//        navigationBar.backgroundColor = UIColor.blue
//        navigationBar.barTintColor = UIColor.blue
//        navigationBar.isTranslucent = false
        
        print("IMAGE ID: "+self.imageID)
        let checkInButton = UIBarButtonItem(image: UIImage(named: "checkInButton"), style: .plain, target: self, action: #selector(viewPostController.checkIn))
        navigationItem.rightBarButtonItem = checkInButton
        //fetch check in
        AWSService().loadCheckIn(self.userID + "_" + (self.imageData?.placeTitle)!, completion: {(result)->Void in
            self.checkInRequest = result
        })



       loadImageDetail()
       loadUIDetails()
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        let cell:MyCustomTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "MyCustomTableViewCell")! as! MyCustomTableViewCell
        
        //self.tableView.contentSize = CGSize(width: self.view.frame.width, height: 400)

    }
    

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

        if segue.identifier == "postComment" {
            if let destinationVC = segue.destination as? PostCommentController{
                
                destinationVC.imageID = imageID
                destinationVC.userName = userName
                destinationVC.userName = userName
                destinationVC.imageObj = self.imageObj
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
        queryExpression.hashKeyValues = self.imageObj?.imageID
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
    
    func calcHeightForCell(cell : UITableViewCell) -> CGFloat{
        cell.layoutIfNeeded()
        var size = cell.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        return size.height
    }
    @IBAction func refresh(_ sender: AnyObject) {
        self.tableView.setNeedsLayout()
        self.tableView.layoutIfNeeded()
        self.tableView.reloadData()
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
            let cell:MyCustomTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "MyCustomTableViewCell")! as! MyCustomTableViewCell
            
            cell.imgView.image = self.imageTapped
            //calculateHotColdScore()
            cell.upvotesLabel.text = String(self.imageObj!.totalScore)
            //Needs styling
            cell.upvotesLabel.textColor = UIColor.white
            cell.captionLabel.textColor = UIColor.white
            cell.userNameLabel.textColor = UIColor.white
                cell.captionLabel.text = self.imageObj?.caption
                cell.userNameLabel.text = self.imageObj?.owner
            //cell.upvoteButton.backgroundColor = UIColor.white
            cell.downvoteButton.isHidden = false
            cell.upvoteButton.isHidden = false
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            return cell
        }else{
        let cell:CommentTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "comments")! as! CommentTableViewCell

        var commentArr = self.commentArray

        tableView.backgroundColor = UIColor.clear
        let border = CALayer()
        let width = CGFloat(1.0)


       let timePosted = commentArr[(indexPath as NSIndexPath).row].timePosted
        
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
        cell.userNameLabel.text = self.imageObj?.owner
            
        cell.commentLabel.text = self.commentArray[indexPath.row].comment
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
        self.performSegue(withIdentifier: "postComment", sender: sender.tag)
    }

}
class MyCustomTableViewCell: UITableViewCell{
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var upvotesLabel: UILabel!
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet var imgView: UIImageView!
    @IBOutlet var upvoteButton: UIButton!
    @IBOutlet var downvoteButton: UIButton!
    

}

class CommentTableViewCell: UITableViewCell{
    
    //@IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!

    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var commentHeight: NSLayoutConstraint!

}
