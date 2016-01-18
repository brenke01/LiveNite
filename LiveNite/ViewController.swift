//
//  ViewController.swift
//  VideoRecord1
//
//  Created by Raj Bala on 9/17/14.
//  Copyright (c) 2014 Raj Bala. All rights reserved.
//

import UIKit
import MediaPlayer
import MobileCoreServices
import AVFoundation
import CoreData
import CoreLocation
import GoogleMaps

var appDel = (UIApplication.sharedApplication().delegate as! AppDelegate)
var context:NSManagedObjectContext = appDel.managedObjectContext!
var upVoteInc : CGFloat = 5
var imageUpvotes = UILabel(frame: CGRectMake(150, upVoteInc, 30, 25))
var idInc : Int = 1

//variables for auto layout code
var noColumns: Int = 2
var imgWidth = 120
var imgHeight = 160






class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, CLLocationManagerDelegate{
    
    @IBOutlet weak var scroller: UIScrollView!

    @IBOutlet
    var tableView : UITableView!
    
    @IBOutlet var collectionView: UICollectionView?
    
    //variable for accessing location
    var locationManager = CLLocationManager()
    var userLocation = CLLocationCoordinate2D()
    var locationUpdated = false
    var toggleState = 0
    var userID = ""
    
    let captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    var captureDevice : AVCaptureDevice?
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if (FBSDKAccessToken.currentAccessToken() == nil)
        {
            print("is nil")
            self.performSegueWithIdentifier("login", sender: nil)
        }
        self.view.hidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.hidden = true
        // Do any additional setup after loading the view, typically from a nib.
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        //layout.sectionInset = UIEdgeInsets(top: 40, left: 0, bottom: 40, right: 5)
        //layout.itemSize = CGSize(width: 120, height: 160)
        //collectionView = UICollectionView(fr, collectionViewLayout: layout)
        collectionView?.dataSource = self
        collectionView!.delegate = self
        
        collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        let nibname = UINib(nibName: "Cell", bundle: nil)
        collectionView!.registerNib(nibname, forCellWithReuseIdentifier: "Cell")
        collectionView!.registerClass(NSClassFromString("GalleryCell"),forCellWithReuseIdentifier:"CELL");

        //collectionView!.backgroundColor = UIColor(red: 42/255, green: 34/255, blue: 34/255, alpha: 1)
        self.view.addSubview(collectionView!)
        
        //location settings
        //needs better error checking
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        if #available(iOS 8.0, *) {
            locationManager.requestWhenInUseAuthorization()
        } else {
            // Fallback on earlier versions
        }
        retrieveUserID()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func retrieveUserID(){
        var id = ""
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, first_name, gender, age_range"])
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if ((error) != nil)
            {
                // Process error
                print("Error: \(error)")
                
            }else{
                id = result.valueForKey("id") as! String
                self.userID = id
            }
        })
    }
    
    @IBAction func profileView(sender: AnyObject) {
        let profileMenu = UIView(frame: CGRect(x: (self.collectionView?.frame.midX)!, y: ((self.collectionView?.frame.maxY)! / 2), width: (self.collectionView?.frame.midX)!, height: ((self.collectionView?.frame.maxY)! / 2)))
        let black = UIColor.blackColor()
        let alphaBlack = black.colorWithAlphaComponent(0.3)
        profileMenu.backgroundColor = alphaBlack
        profileMenu.tag = 100
        let nameLabel = UILabel(frame: CGRect(x: 15, y: 0, width: profileMenu.frame.maxX, height: profileMenu.frame.maxY / 8))
        if toggleState == 0{
            toggleState = 1
            print(self.userID)
            let fetchRequest = NSFetchRequest(entityName: "Users")
            fetchRequest.predicate = NSPredicate(format: "id= %@", self.userID)
            let user = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
            var userName = user![0].valueForKey("first_name")
            nameLabel.text = userName as! String
            nameLabel.textColor = UIColor.whiteColor()
            profileMenu.addSubview(nameLabel)
            self.view.addSubview(profileMenu)
        }else{
            toggleState = 0
            var viewWithTag = self.view.viewWithTag(100)! as UIView
            viewWithTag.removeFromSuperview()
        }
        
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let fetchRequest = NSFetchRequest(entityName: "Entity")
        let locations = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        return locations!.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as UICollectionViewCell
        cell.backgroundColor = UIColor.yellowColor()
        
        let fetchRequest = NSFetchRequest(entityName: "Entity")
        cell.backgroundColor = UIColor.blackColor()
        
        let locations = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        var idArray : [Int] = []
        var imageArray : [UIImage] = []
        
        var upVoteArray : [Int] = []
        if let locations = locations{
            for loc in locations{
                
                let imageData: AnyObject? = loc.valueForKey("videoData")
                let imgData = UIImage(data: (imageData as? NSData)!)
                imageArray.append(imgData!)
                let idData : AnyObject? = loc.valueForKey("id")
                let imageId = idData as? Int
                idArray.append(imageId!)
                let upVoteData : AnyObject? = loc.valueForKey("upvotes")
                let upVotes = upVoteData as? Int
                upVoteArray.append(upVotes!)

                
                
                
            
            }
        }
        var imageButton = UIButton(frame: CGRectMake(0, 0, CGFloat(imgWidth), CGFloat(imgHeight)))
        imageButton.setImage(imageArray[indexPath.row], forState: .Normal)
        imageButton.addTarget(self, action: "viewPost:", forControlEvents: .TouchUpInside)
        imageButton.userInteractionEnabled = true
        
        imageButton.tag = idArray[indexPath.row]
        let layer = imageButton.layer
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowOffset = CGSize(width: 0, height: 20)
        layer.shadowOpacity = 0.4
        layer.shadowRadius = 5
        cell.addSubview(imageButton)
        return cell
    }
    
    //begin auto layout code
    
    //set size of each square cell to imgSize
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let size = CGSize(width: imgWidth, height: imgHeight)
        return size
    }
    
    //calculate offset based on screensize, number of columns, and size of cell then use it to apply the inset
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let screenWidth = screenSize.width
        let offset = (screenWidth - CGFloat(noColumns*imgWidth)) / CGFloat(noColumns+1)
        let sectionInset = UIEdgeInsets(top: offset/2, left: offset, bottom: offset/2, right: offset)
        return sectionInset
    }
    
    //calculate offset based on screensize, number of columns, and size of cell then use it to set space between lines
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat{
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let screenWidth = screenSize.width
        let offset = (screenWidth - CGFloat(noColumns*imgWidth)) / CGFloat(2*(noColumns+1))
        return offset
    }
    
    //end auto layout code
    
    //get user location function
    //all you need to do to get user location is locationManager.startUpdatingLocation()
    //it will start getting the users location in the background 
    //call it when they open the camera to take a picture so it has a few seconds to settle
    //store userLocation in the database once picture is taken (error check to make sure it got a location)
    //call locationManager.stopUpdatingLocation once location has been stored and reset locationUpdated to false
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations[0].coordinate
        print("\(userLocation.latitude) Degrees Latitude, \(userLocation.longitude) Degrees Longitude")
        locationUpdated = true
    }
    
    
    @IBAction func capVideo() {
        
        
        self.performSegueWithIdentifier("PickLocation", sender: 1)
        
    }

    
    func viewPost(sender: AnyObject){
        print(sender)
        self.performSegueWithIdentifier("viewPost", sender: sender.tag)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print(segue.identifier)
        if segue.identifier == "viewPost" {
            print("test")
            if let destinationVC = segue.destinationViewController as? viewPostController{
                
                let fetchRequest = NSFetchRequest(entityName: "Entity")
                
                fetchRequest.predicate = NSPredicate(format: "id= %i", sender as! Int)
                let images = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
                
                if let images = images{
                    for img in images{
                        
                        let imageID: AnyObject? = img.valueForKey("id")
                        let imageUpvotes : AnyObject? =
                            img.valueForKey("upvotes")
                        let imageData : AnyObject? = img.valueForKey("videoData")
                        let imageTitle : AnyObject? = img.valueForKey("title")
                        destinationVC.imageUpvotes = (imageUpvotes as? Int)!
                        print(imageID)
                        destinationVC.imageTapped = UIImage(data: (imageData as? NSData)!)!
                        destinationVC.imageID = (imageID as? Int)!
                        destinationVC.imageTitle = (imageTitle as? String)!
                        
                    }
                }
            }
        }else if segue.identifier == "PickLocation"{
            
            if let destinationVC = segue.destinationViewController as? PickLocationController{
                
                destinationVC.locations = 1
            }
        }else if segue.identifier == "login"{
            if let destinationVC = segue.destinationViewController as? FBLoginController{
                print("login controller")
                destinationVC.locations = 1
            }
        }
    }
    

    /*func tableView(tableView: UITableView, numberOfRowsInSection section: Int)-> Int {
        let fetchRequest = NSFetchRequest(entityName: "Entity")
        let locations = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        return locations!.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath)-> UITableViewCell {
        
        let label = UILabel(frame: CGRectMake(15, 5, 250, 50))
        
        var i = 0
        
        label.text = "Fun at Blarneys"
        label.font = UIFont(name:"HelveticaNeue-Bold", size: 18.0)
        let commitLabel = UILabel(frame: CGRectMake(15, 440, 105, 30))
        commitLabel.font = UIFont(name:"HelveticaNeue-Bold", size: 18.0)
        commitLabel.text = " I'M GOING"
        commitLabel.backgroundColor = UIColor.yellowColor()
        commitLabel.textColor = UIColor.blackColor()
        let upVotebutton : UIButton = UIButton(frame: CGRectMake(220, 440, 40, 40))
        let downVoteButton = UIButton(frame: CGRectMake(260, 440, 40, 40))
        
        let upVoteImage = UIImage(named: "UpVote")
       
        upVotebutton.setBackgroundImage(upVoteImage, forState: UIControlState.Normal)
        //upVotebutton.backgroundColor = UIColor.yellowColor()
        
        let downVoteImage = UIImage(named: "DownVote")
        
        downVoteButton.setBackgroundImage(downVoteImage, forState: UIControlState.Normal)
        downVoteButton.addTarget(self, action: "DownVote:", forControlEvents: UIControlEvents.TouchUpInside)
        
        
        
        upVotebutton.addTarget(self, action: "UpVote:", forControlEvents: UIControlEvents.TouchUpInside)
        label.textColor = UIColor.whiteColor()
        self.tableView.rowHeight = 480
        //let cell : UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell") as! UITableViewCell
        

       
        let fetchRequest = NSFetchRequest(entityName: "Entity")
        //cell.backgroundColor = UIColor.blackColor()
        
        let locations = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        var idArray : [Int] = []
        var imageArray : [UIImage] = []
        
        var upVoteArray : [Int] = []
        if let locations = locations{
            for loc in locations{
                
                let imageData: AnyObject? = loc.valueForKey("videoData")
                let imgData = UIImage(data: (imageData as? NSData)!)
                imageArray.append(imgData!)
                let idData : AnyObject? = loc.valueForKey("id")
                let imageId = idData as? Int
                idArray.append(imageId!)
                let upVoteData : AnyObject? = loc.valueForKey("upvotes")
                let upVotes = upVoteData as? Int
                upVoteArray.append(upVotes!)
                
                
                
                
                
            }
        }
       
        

        upVotebutton.tag = idArray[indexPath.row]
        downVoteButton.tag = idArray[indexPath.row]
        if cell.viewWithTag(100) == nil{
            
            let upVoteLabel = UILabel(frame: CGRectMake(15, 400, 50, 50))
            upVoteLabel.textColor = UIColor.whiteColor()
            upVoteLabel.text = "\(upVoteArray[indexPath.row])"
            upVoteLabel.font = UIFont(name:"HelveticaNeue-Bold", size: 18.0)
            upVoteLabel.tag = 100
            cell.addSubview(upVoteLabel)
            
            
        }else{
            let upVoteLabel = cell.viewWithTag(100) as! UILabel
            print(upVoteArray[indexPath.row], terminator: "")
            upVoteLabel.text = "\(upVoteArray[indexPath.row])"
            cell.addSubview(upVoteLabel)
            
        }
        cell.addSubview(commitLabel)
        cell.addSubview(label)
        cell.addSubview(upVotebutton)
        cell.addSubview(downVoteButton)
        let imageContainer = UIImageView(frame: CGRectMake(0, 50, 320, 350))
        imageContainer.image = imageArray[indexPath.row]
        cell.addSubview(imageContainer)

        
       return cell
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var selectedCell = tableView.cellForRowAtIndexPath(indexPath)
        //selectedCell?.contentView.backgroundColor = UIColor.blackColor()
        print("selected", terminator: "")
        var imageDetails = UIView(frame: CGRectMake(0, 0, 325, 600))
        let fetchRequest = NSFetchRequest(entityName: "Entity")

        
        let locations = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        var idArray : [Int] = []
        var imageArray : [UIImage] = []
        
        var upVoteArray : [Int] = []
        if let locations = locations{
            for loc in locations{
                
                let imageData: AnyObject? = loc.valueForKey("videoData")
                let imgData = UIImage(data: (imageData as? NSData)!)
                imageArray.append(imgData!)
                let idData : AnyObject? = loc.valueForKey("id")
                let imageId = idData as? Int
                idArray.append(imageId!)
                let upVoteData : AnyObject? = loc.valueForKey("upvotes")
                let upVotes = upVoteData as? Int
                upVoteArray.append(upVotes!)
                
                
                
                
                
            }
        }
        
        
    }*/

    
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.collectionView?.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    


    //Reconstruct to use tableView
    func loadImageFeed(){
        let fetchRequest = NSFetchRequest(entityName: "Entity")
        var count : CGFloat = 70
        var imageCount : CGFloat = 30
        let containerCount : CGFloat = 300
        
        let locations = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        let multiplier : Int = locations!.count

        let imageContainer = UIView(frame: CGRectMake(5, 50, 300, containerCount * CGFloat(multiplier)))
        if let locations = locations{
            for loc in locations{
                print("test", terminator: "")
                let imageData: AnyObject? = loc.valueForKey("videoData")
                let imageText : AnyObject? = loc.valueForKey("title")
                var upVoteCount : AnyObject? = loc.valueForKey("upvotes")
                let imageId : AnyObject? = loc.valueForKey("id")
                let imgData = UIImage(data: (imageData as? NSData)!)
                var img : UIImageView
                let imageviewObj = UIImageView(frame: CGRectMake(5, imageCount, 300, 250))
                imageviewObj.image = imgData
                
                
                let imageTitle : UILabel = UILabel(frame: CGRectMake(5,upVoteInc, 150, 25))
                
                imageUpvotes = UILabel(frame: CGRectMake(150, upVoteInc, 30, 25))
                imageUpvotes.textColor = UIColor.blackColor()
                let upVotebutton : UIButton = UIButton(frame: CGRectMake(250,upVoteInc, 70, 25))
                upVoteCount = upVoteCount as? Int
                imageUpvotes.text = "\(upVoteCount!)"
                upVotebutton.setTitle("^", forState: UIControlState.Normal)
                
                //var upVoteLabel: UILabel = UILabel(frame: CGRectMake(180, containerCount, 20, 25))
                upVotebutton.addTarget(self, action: "UpVote:", forControlEvents: UIControlEvents.TouchUpInside)
                let id = imageId as! Int
                upVotebutton.tag = id
                upVotebutton.backgroundColor = UIColor.blackColor()
                
                //upVoteLabel.text = upVoteCount as? String
                //upVoteLabel.textColor = UIColor.whiteColor()
                //imageTitle.addSubview(upVoteLabel)
                
                imageTitle.textColor = UIColor.blackColor()
                imageTitle.text = imageText as? String
                imageContainer.addSubview(imageviewObj)
                
                
                imageContainer.sendSubviewToBack(imageUpvotes)
                imageContainer.addSubview(imageTitle)
                
                imageContainer.addSubview(upVotebutton)
                imageContainer.addSubview(imageUpvotes)
                
                imageContainer.backgroundColor = UIColor.yellowColor()
                
                
                scroller.contentSize = imageContainer.bounds.size
                
                scroller.addSubview(imageContainer)
                scroller.sendSubviewToBack(imageContainer)
                
                
                
                count = count + 300
                
                imageCount += 300
                upVoteInc += 300
                
                
                
            }
            
        }
        
        self.view.addSubview(scroller)
        

        
    }
    
    func UpVote(sender: UIButton){
        print(sender.tag, terminator: "")
        let id = 0
        let disableMyButton = sender as UIButton
        disableMyButton.enabled = false
        let disableUpVoteImage = UIImage(named: "UpVoted")
        disableMyButton.setBackgroundImage(disableUpVoteImage, forState: UIControlState.Normal)
        let fetchRequest = NSFetchRequest(entityName: "Entity")
        fetchRequest.predicate = NSPredicate(format: "id = %i", sender.tag)
        let locations = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        if let locations = locations{
            
            for loc in locations{
                let idData : AnyObject? = loc.valueForKey("id")
                let id = idData as! Int
                print(id, terminator: "")
                let upvoteData : AnyObject? = loc.valueForKey("upvotes")
                var upvote = upvoteData as! Int
                upvote = upvote + 1
                
                loc.setValue(upvote, forKey: "upvotes")
                do {
                    try context.save()
                } catch _ {
                }
                
                
                
            }
            
            
            
            
            
            
        }
        userUpvoted(id)
        self.collectionView!.reloadData()
        
    }
    
    func userUpvoted(id : Int){
        
    }
    func DownVote(sender: UIButton){
        print(sender.tag, terminator: "")
        let fetchRequest = NSFetchRequest(entityName: "Entity")
        fetchRequest.predicate = NSPredicate(format: "id = %i", sender.tag)
        let locations = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        if let locations = locations{
            
            for loc in locations{
                
                let idData : AnyObject? = loc.valueForKey("id")
                let id = idData as! Int
                print(id, terminator: "")
                let upvoteData : AnyObject? = loc.valueForKey("upvotes")
                var upvote = upvoteData as! Int
                upvote = upvote - 1
                loc.setValue(upvote, forKey: "upvotes")
                do {
                    try context.save()
                } catch _ {
                }
                
                
                
            }
            
            
            
            
            
            
        }
       
        self.collectionView?.reloadData()
        
    }
    


}

