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
    var hotToggle = 0
    
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
        let alphaBlack = black.colorWithAlphaComponent(0.7)
        profileMenu.backgroundColor = alphaBlack
        profileMenu.tag = 100
        let medalLabel = UILabel(frame: CGRect(x: 15, y: 5, width: profileMenu.frame.width / 4, height: profileMenu.frame.height / 5))
        
        let nameLabel = UILabel(frame: CGRect(x: profileMenu.frame.width / 4, y: profileMenu.frame.height / 25, width: profileMenu.frame.width - profileMenu.frame.width / 4, height: profileMenu.frame.height / 5))
        let scoreLabel = UILabel(frame: CGRect(x: profileMenu.frame.width / 4, y: profileMenu.frame.maxX / 20, width: profileMenu.frame.width - profileMenu.frame.width / 4, height: profileMenu.frame.maxY / 5))
        
        let myFriendsLabel = UILabel(frame: CGRect(x: 15, y: profileMenu.frame.height / 3, width: profileMenu.frame.width, height: profileMenu.frame.height / 5))
        
        if toggleState == 0{
            toggleState = 1
            print(self.userID)
            let fetchRequest = NSFetchRequest(entityName: "Users")
            fetchRequest.predicate = NSPredicate(format: "id= %@", self.userID)
            let user = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
            let userName = user![0].valueForKey("first_name")
            let score = user![0].valueForKey("score")
            nameLabel.text = userName as! String
            scoreLabel.text = String(score!)
            myFriendsLabel.text = "My VIP"
            myFriendsLabel.textColor = UIColor.whiteColor()
            nameLabel.textColor = UIColor.whiteColor()
            scoreLabel.textColor = UIColor.whiteColor()

            profileMenu.addSubview(medalLabel)
            profileMenu.addSubview(nameLabel)
            profileMenu.addSubview(scoreLabel)
            profileMenu.addSubview(myFriendsLabel)
            self.view.addSubview(profileMenu)
        }else{
            toggleState = 0
            let viewWithTag = self.view.viewWithTag(100)! as UIView
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
        if (self.hotToggle == 1){
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "upvotes", ascending: false)]
        }else{
             fetchRequest.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
        }
        let locations = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        var idArray : [Int] = []
        var imageArray : [UIImage] = []
        
        var upVoteArray : [Int] = []
        if let locations = locations{
            for loc in locations{
                
                let imageData: AnyObject? = loc.valueForKey("imageData")
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
        let imageButton = UIButton(frame: CGRectMake(0, 0, CGFloat(imgWidth), CGFloat(imgHeight)))
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
    
    @IBAction func getHotImages(sender: AnyObject) {
        self.hotToggle = 1
        collectionView?.reloadData()
    }
    
    @IBAction func getRecentImages(sender: AnyObject) {
        self.hotToggle = 0
        collectionView?.reloadData()
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
                        let imageData : AnyObject? = img.valueForKey("imageData")
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

    
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.collectionView?.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

