//
//  NotificationController.swift
//  LiveNite
//
//  Created by Kevin  on 12/30/16.
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

class NotificationController: UIViewController, UITableViewDelegate, UITableViewDataSource{

    @IBOutlet weak var tableView: UITableView!
    var notificationArray = [Notification]()
    var user = User()
    var userID = ""
    var uiImageArr = [UIImage]()
    var chosenImage = UIImage()
    var chosenImageObj = Image()
    var activityIndicator = UIActivityIndicatorView()
    var arrayEmpty = false
    var emptyArrayLabel = UILabel()
    var tryAgainButton = UILabel()

    
    override func viewDidLoad(){
        super.viewDidLoad()
        self.refreshControl.tintColor = UIColor.white
        self.tabBarController?.tabBar.items?[3].badgeValue = nil
        self.tableView.addSubview(self.refreshControl)
        navigationController?.navigationBar.tintColor = UIColor.white

        navigationItem.backBarButtonItem?.tintColor = UIColor.white
        navigationItem.title = "Notifications"
        tableView.delegate = self
        tableView.dataSource = self
        self.tableView.isHidden = true
        self.progressBarDisplayer("Loading", true)

        if (self.user?.userID == ""){
            retrieveUserID({(result)->Void in
                self.userID = result
                AWSService().loadUser(self.userID,completion: {(result)->Void in

                    self.user = result
                    self.getNotificationArray()
                    
                })
                
            })
        }

        
  
        
        
    }
    
    func getNotificationArray(){
        self.getNotifications(completion: {(result)->Void in
            self.notificationArray = result
            if (self.notificationArray.count == 0){
                self.arrayEmpty = true
                 self.tableView.isHidden = false
                 DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
                })
            }else{
                self.arrayEmpty = false
                self.notificationArray = (self.notificationArray as NSArray).sortedArray(using: [
                    NSSortDescriptor(key: "actionTime", ascending: false)
                    ]) as! [Notification]
                DispatchQueue.main.async(execute: {
                    self.updateOpenNotifications(notifArray: self.notificationArray)
                })
                for n in self.notificationArray{
                    var bucket : String
                    if(n.type == "meetUp"){
                        bucket = "liveniteprofileimages"
                    }
                    else{
                        bucket = "liveniteimages"
                    }
                    AWSService().getImageFromUrl(String(n.imageID), bucket: bucket, completion: {(result)->Void in
                        DispatchQueue.main.async(execute: {
                            self.uiImageArr.append(result)
                            
                            self.tableView.isHidden = false
                            self.tableView.reloadData()
                            
                        })
                    })
                }
            }
            
            
        })
    }
    
    func updateOpenNotifications(notifArray : [Notification]){
        for n in self.notificationArray{
            if (n.open == true){
                n.open = false
                AWSService().save(n)
            }
        }
    }
    
    func progressBarDisplayer(_ msg:String, _ indicator:Bool ) {
        
        if indicator {
            
            
            activityIndicator.frame = CGRect(x:self.view.frame.midX - 50, y: self.view.frame.midY - 100, width: 100, height: 100)
            activityIndicator.startAnimating()
            
        }
        
        self.view?.addSubview(activityIndicator)
    }
    
    func handleRefresh(_ refreshControl: UIRefreshControl){
        AWSService().loadUser(self.userID,completion: {(result)->Void in
            
            self.user = result
            self.getNotificationArray()
            
        })
        
    }
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        return refreshControl
    }()
    
        func retrieveUserID(_ completion:@escaping (_ result: String)->Void){
            var id = ""
            let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, first_name, gender, age_range"])
            graphRequest.start(completionHandler: { (connection, result, error) -> Void in
                
                if ((error) != nil)
                {
                    // Process error
                    print("Error: \(error)")
                    
                }else{
                    let data:[String:AnyObject] = result as! [String: AnyObject]
                    let userID = data["id"] as? String
                    completion(userID!)
                    
                }
                
            })
            
            
        }

    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section : Int) -> Int{
        if (self.arrayEmpty){
            return 1
        }else{
            return self.notificationArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:NotificationCell = self.tableView.dequeueReusableCell(withIdentifier: "notificationCell")! as! NotificationCell
        cell.selectionStyle = UITableViewCellSelectionStyle.none

        if (!self.arrayEmpty){
            cell.notifImage.layer.borderWidth = 0
            cell.notifImage.layer.borderColor = UIColor.clear.cgColor
            cell.userNameLabel.text = self.notificationArray[indexPath.row].userName
            if self.notificationArray[indexPath.row].type == "checkIn"{
                cell.notificationLabel.text = "checked in"
            }else if self.notificationArray[indexPath.row].type == "comment"{
                cell.notificationLabel.text = "commented on your post."
            }else if self.notificationArray[indexPath.row].type == "meetUp"{
                cell.notificationLabel.text = "and you met up!"
            }
            let timePosted = notificationArray[(indexPath as NSIndexPath).row].actionTime
            cell.notifImage.image = self.uiImageArr[indexPath.row]
            cell.notifImage.contentMode = UIViewContentMode.scaleAspectFit
            DispatchQueue.main.async(execute: {
            if (self.notificationArray[(indexPath as NSIndexPath).row].type != "meetUp"){
                cell.notifImage.layer.borderWidth = 2
                cell.notifImage.layer.borderColor = UIColor.white.cgColor
                }})

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
            
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
            cell.timeLabel.text = intervalStr
        
        }else if (self.arrayEmpty){
             DispatchQueue.main.async(execute: {
            for v  in cell.subviews{
            v.removeFromSuperview()
            }
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
            
            self.emptyArrayLabel = UILabel(frame: CGRect(x: 0, y: ((self.tableView?.frame.height)! / 2) - 75, width: self.view.frame.width, height: 50))
            self.tryAgainButton = UILabel(frame: CGRect(x: 0, y: ((self.tableView?.frame.height)! / 2) - 50, width: self.view.frame.width, height: 50))
            self.tryAgainButton.text = "Tap to retry"
            self.tryAgainButton.textAlignment = .center
            self.tryAgainButton.textColor = UIColor.white
            self.tryAgainButton.layer.masksToBounds = true
            
            self.emptyArrayLabel.text = "You have no notifications"
            self.tryAgainButton.font = UIFont.boldSystemFont(ofSize: 16)
            self.emptyArrayLabel.textColor = UIColor.white
            self.emptyArrayLabel.textAlignment = .center
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
            self.refreshControl.endRefreshing()
            
            cell.addSubview(self.tryAgainButton)
            cell.addSubview(self.emptyArrayLabel)
            })
        
        
        }
    
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        if (self.arrayEmpty){
            self.emptyArrayLabel.removeFromSuperview()
            self.tryAgainButton.removeFromSuperview()
            progressBarDisplayer("Loading", true)
            AWSService().loadUser(self.userID,completion: {(result)->Void in
                
                self.user = result
                self.getNotificationArray()
                
            })
        }else{
       
            AWSService().loadImage(self.notificationArray[indexPath.row].imageID,completion: {(result)->Void in
                 self.chosenImage = self.uiImageArr[indexPath.row]
                self.chosenImageObj = result
                 self.performSegue(withIdentifier: "viewPostFromNotifications", sender: 1)
            })
        }
       
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath)-> CGFloat{
        if (self.arrayEmpty){
            return self.view.frame.height
        }else{
            return UITableViewAutomaticDimension
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print(segue.identifier)
        if segue.identifier == "viewPostFromNotifications" {
            
            if let destinationVC = segue.destination as? viewPostController{
                
                destinationVC.imageTapped = self.chosenImage

                destinationVC.imageObj = self.chosenImageObj
                destinationVC.imageID = (self.chosenImageObj?.imageID)!
                destinationVC.user = self.user
            }
        }}
    
    func getNotifications(completion:@escaping ([Notification])->Void)->[Notification]{
        
        var notificationArray = [Notification]()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.indexName = "ownerName-index"
        queryExpression.keyConditionExpression = "ownerName = :ownerName"
        queryExpression.filterExpression = "userName <> :userName"
        queryExpression.expressionAttributeValues = [":ownerName": self.user?.userName, ":userName": self.user?.userName]
        
        
        
        dynamoDBObjectMapper.query(Notification.self, expression: queryExpression).continue({(task: AWSTask) -> AnyObject in
            if (task.error != nil) {
                print("The request failed. Error: [\(task.error)]")
            }
            if (task.exception != nil) {
                print("The request failed. Exception: [\(task.exception)]")
            }
            if (task.result != nil) {
                let output : AWSDynamoDBPaginatedOutput = task.result!
                for notification  in output.items {
                    let notification : Notification = notification as! Notification
                    notificationArray.append(notification)
                }
                completion(notificationArray)
                return notificationArray as AnyObject
                
            }
            return notificationArray as AnyObject
        })
        
        
        return notificationArray
        
    }

}

class NotificationCell: UITableViewCell{
    @IBOutlet weak var notificationLabel : UILabel!
    @IBOutlet weak var notifImage: UIImageView!
    @IBOutlet weak var timeLabel : UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
}
