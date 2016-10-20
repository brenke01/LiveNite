//
//  CommentController.swift
//  LiveNite
//
//  Created by Kevin  on 6/14/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//

import Foundation
import MobileCoreServices
import CoreData
import CoreLocation
import AWSDynamoDB

class CommentController: UIViewController, UITableViewDelegate, CLLocationManagerDelegate,UITableViewDataSource{
    @IBAction func back(sender: AnyObject) {
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    @IBOutlet weak var navBar: UINavigationBar!
    
    @IBOutlet weak var tableView: UITableView!
    var imageID = ""
    var userNameOP = ""
    var userName = ""
    var commentInfoArray : [[String:String]] = []
    
    override func viewDidLoad() {
        let navBarBGImage = UIImage(named: "Navigation_Bar_Gold")
        navBar.setBackgroundImage(navBarBGImage, forBarMetrics: .Default)
        navBar.topItem!.title = "Comments"
        //self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "CommentList")
        tableView.dataSource = self
        tableView.delegate = self
        loadComments()
        self.tableView.estimatedRowHeight = 168.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        super.viewDidLoad()

    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        let cell : UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        let cellText : String = (cell.textLabel?.text)!
        
    }
    
    func numberOfSectionsinTableView(tableView: UITableView) -> Int{
        return 1
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int)-> Int{
        return self.commentInfoArray.count
    }
    
    func loadComments()-> [Comment]{

        var commentArray = [Comment]()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.hashKeyAttribute = "commentID"
        queryExpression.rangeKeyConditionExpression = "imageID = :val"
        queryExpression.expressionAttributeValues = [":val": imageID]
        dynamoDBObjectMapper.query(Image.self, expression: queryExpression).continueWithBlock({(task: AWSTask) -> AnyObject in
            if (task.error != nil) {
                print("The request failed. Error: [\(task.error)]")
            }
            if (task.exception != nil) {
                print("The request failed. Exception: [\(task.exception)]")
            }
            if (task.result != nil) {
                let output : AWSDynamoDBPaginatedOutput = task.result as! AWSDynamoDBPaginatedOutput
                for comment  in output.items {
                    let comment : Comment = comment as! Comment
                    commentArray.append(comment)
                }
            }
            return commentArray
        })
        
        return commentArray

    }
    
    
    func tableView(tableView:UITableView, cellForRowAtIndexPath
        indexPath: NSIndexPath)-> UITableViewCell{
        var commentArr = loadComments()
        let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("CommentList")! as UITableViewCell
        tableView.backgroundColor = UIColor.clearColor()
        let border = CALayer()
        let width = CGFloat(1.0)

        
        
/*        self.tableView.rowHeight = 50
        
        var commentInfoContainer = UIView(frame: CGRect(x: 10, y:5, width: (cell.frame.maxX), height: cell.frame.maxY))
        var userNameContainer = UIView(frame: CGRect(x: 0, y: 0, width: (cell.frame.maxX), height: cell.frame.maxY / 2))
        var userNameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: (cell.frame.maxX), height: cell.frame.maxY / 2))
        userNameLabel.text = self.commentInfoArray[indexPath.row]["owner"]
        userNameLabel.textColor = UIColor.whiteColor()
        
        userNameContainer.addSubview(userNameLabel)
        
        commentInfoContainer.addSubview(userNameContainer)
        var commentContainer = UIView(frame: CGRect(x: 0, y: 0, width: (cell.frame.maxX), height: cell.frame.maxY / 2))
        var commentLabel = UILabel(frame: CGRect(x: 0, y: cell.frame.maxY / 2, width: cell.frame.maxX, height: cell.frame.maxY))
        commentLabel.textColor = UIColor.whiteColor()
        
        commentLabel.text = self.commentInfoArray[indexPath.row]["comment"]
        commentContainer.addSubview(commentLabel)
        commentInfoContainer.addSubview(commentContainer)
        
        cell.addSubview(commentInfoContainer)*/
        
        let nameLabel : UILabel = (cell.viewWithTag(100) as! UILabel)
        let commentLabel : UILabel = (cell.viewWithTag(200) as! UILabel)
        let timeLabel : UILabel = (cell.viewWithTag(300) as! UILabel)
        let timePosted = commentArr[indexPath.row].timePosted
       
        let dateFormatter = NSDateFormatter()
        let localeStr = "us"
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = NSLocale(localeIdentifier: localeStr)
        let timePostedFormatted = dateFormatter.dateFromString(timePosted)
        let now = NSDate()
        var interval = now.timeIntervalSinceDate(timePostedFormatted!)
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
        timeLabel.text = intervalStr
        timeLabel.textColor = UIColor.whiteColor()
        nameLabel.text = commentArr[indexPath.row].owner
        commentLabel.text = commentArr[indexPath.row].comment
        border.borderColor = UIColor.whiteColor().CGColor
        border.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1)
        border.borderWidth = width
        tableView.layer.addSublayer(border)
        
        tableView.opaque = false
        cell.backgroundColor = UIColor.clearColor()
        cell.opaque = false
        cell.textLabel?.textColor = UIColor.whiteColor()

        return cell
    }

    @IBAction func exit(sender: AnyObject) {
         self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    @IBAction func postComment(sender: AnyObject) {
        self.performSegueWithIdentifier("postComment", sender: sender.tag)
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "postComment" {
            if let destinationVC = segue.destinationViewController as? PostCommentController{
                
                destinationVC.imageID = imageID
                destinationVC.userName = userName
                destinationVC.userName = userName
            }
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

            tableView.reloadData()
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.reloadData()
        
        
    }
    

    

}

