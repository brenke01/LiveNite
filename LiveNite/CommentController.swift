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
    @IBAction func back(_ sender: AnyObject) {
        self.dismiss(animated: false, completion: nil)
    }
    @IBOutlet weak var navBar: UINavigationBar!
    
    @IBOutlet weak var tableView: UITableView!
    var imageID = ""
    var userNameOP = ""
    var userName = ""
    var commentInfoArray : [[String:String]] = []
    
    override func viewDidLoad() {
        let navBarBGImage = UIImage(named: "Navigation_Bar_Gold")
        navBar.setBackgroundImage(navBarBGImage, for: .default)
        navBar.topItem!.title = "Comments"
        //self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "CommentList")
        tableView.dataSource = self
        tableView.delegate = self
        loadComments()
        self.tableView.estimatedRowHeight = 168.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        super.viewDidLoad()

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let cell : UITableViewCell = tableView.cellForRow(at: indexPath)!
        let cellText : String = (cell.textLabel?.text)!
        
    }
    
    func numberOfSectionsinTableView(_ tableView: UITableView) -> Int{
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)-> Int{
        return self.commentInfoArray.count
    }
    
    func loadComments()-> [Comment]{

        var commentArray = [Comment]()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.hashKeyAttribute = "commentID"
        queryExpression.rangeKeyConditionExpression = "imageID = :val"
        queryExpression.expressionAttributeValues = [":val": imageID]
        dynamoDBObjectMapper.query(Image.self, expression: queryExpression).continue({(task: AWSTask) -> AnyObject in
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
            }
            return commentArray as AnyObject
        })
        
        return commentArray

    }
    
    
    func tableView(_ tableView:UITableView, cellForRowAt
        indexPath: IndexPath)-> UITableViewCell{
        var commentArr = loadComments()
        let cell:UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "CommentList")! as UITableViewCell
        tableView.backgroundColor = UIColor.clear
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
        let timePosted = commentArr[(indexPath as NSIndexPath).row].timePosted
       
        let dateFormatter = DateFormatter()
        let localeStr = "us"
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
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
        timeLabel.text = intervalStr
        timeLabel.textColor = UIColor.white
        nameLabel.text = commentArr[(indexPath as NSIndexPath).row].owner
        commentLabel.text = commentArr[(indexPath as NSIndexPath).row].comment
        border.borderColor = UIColor.white.cgColor
        border.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1)
        border.borderWidth = width
        tableView.layer.addSublayer(border)
        
        tableView.isOpaque = false
        cell.backgroundColor = UIColor.clear
        cell.isOpaque = false
        cell.textLabel?.textColor = UIColor.white

        return cell
    }

    @IBAction func exit(_ sender: AnyObject) {
         self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func postComment(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "postComment", sender: sender.tag)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "postComment" {
            if let destinationVC = segue.destination as? PostCommentController{
                
                destinationVC.imageID = imageID
                destinationVC.userName = userName
                destinationVC.userName = userName
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

            tableView.reloadData()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.reloadData()
        
        
    }
    

    

}

