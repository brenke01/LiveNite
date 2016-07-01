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

class CommentController: UIViewController, UITableViewDelegate, CLLocationManagerDelegate,UITableViewDataSource{
    @IBAction func back(sender: AnyObject) {
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    @IBOutlet weak var navBar: UINavigationBar!
    
    @IBOutlet weak var tableView: UITableView!
    var imageID = 0
    var userNameOP = ""
    var userName = ""
    var commentInfoArray : [[String:String]] = []
    
    override func viewDidLoad() {
        let navBarBGImage = UIImage(named: "Navigation_Bar_Gold")
        navBar.setBackgroundImage(navBarBGImage, forBarMetrics: .Default)
        navBar.topItem!.title = "Comments"
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        loadComments()
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
    
    func loadComments(){
        let fetchRequest = NSFetchRequest(entityName: "Comments")
        
        fetchRequest.predicate = NSPredicate(format: "image_id= %i", imageID as! Int)
        let comments = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        
        if let comments = comments{
            for comment in comments{
                
                let commentPosted: AnyObject? = comment.valueForKey("comment")
                let owner : AnyObject? =
                    comment.valueForKey("owner")
                var commentInfo : [String: String] = [:]
                commentInfo["owner"] = owner as? String
                commentInfo["comment"] = commentPosted as! String
                self.commentInfoArray.append(commentInfo)
                
            }
        }
    }
    
    
    func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath: NSIndexPath)-> UITableViewCell{
        let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell
        tableView.backgroundColor = UIColor.clearColor()
        let border = CALayer()
        let width = CGFloat(1.0)

        
     
            cell.textLabel?.text = self.commentInfoArray[indexPath.row]["comment"]
        
        
        
        
        
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
                
                destinationVC.imageID = (imageID as? Int)!
                destinationVC.userName = (userName as? String)!
                destinationVC.userName = (userName as? String)!
            }
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

            tableView.reloadData()
        
        
    }

}