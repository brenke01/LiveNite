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
    var hotToggle = 0
    var profileMenu = UIView()
    let captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    var captureDevice : AVCaptureDevice?
    var accessToken = ""
    var userID = ""
    var userName = ""
    var placesToggle = false
    var displayPlacesAlbum = false
    var chosenAlbumLocation = ""
    var previousLocationName = ""
    var idArray : [String] = []
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        if (item.tag == 1){
            self.placesToggle = false
            self.displayPlacesAlbum = false
            self.collectionView?.reloadData()
        }else if (item.tag == 2){
            
        }else if (item.tag == 3){
            capVideo()
        }else if (item.tag == 4){
            
        }else if (item.tag == 5){
            profileView()
        }
    }
    
    
    @IBOutlet weak var sortBtn: UIButton!
    @IBAction func toggleSort(sender: AnyObject) {
        if (self.hotToggle == 0){
            sortBtn.setTitle("Popular", forState: UIControlState.Normal)
            getHotImages()
        }else{
            sortBtn.setTitle("Recent", forState: UIControlState.Normal)
            getRecentImages()
        }
    }
    
    func getHotImages() {
        
        self.hotToggle = 1
        collectionView?.reloadData()
        
    }
    
    func getRecentImages() {
        
        self.toggleState = 0
        self.hotToggle = 0
        
        collectionView?.reloadData()
    }
    
    @IBOutlet weak var imagesTypeBtn: UIButton!

    @IBAction func getPlacesView(sender: AnyObject) {
        if (!self.placesToggle){
            self.placesToggle = true
            imagesTypeBtn.setTitle("Places", forState: UIControlState.Normal)
        }else{
            imagesTypeBtn.setTitle("People", forState: UIControlState.Normal)
            self.placesToggle = false
        }
        self.collectionView?.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        self.view.hidden = false
        if (FBSDKAccessToken.currentAccessToken() == nil)
        {
            print("is nil")
            self.performSegueWithIdentifier("login", sender: nil)
        }else{
            self.accessToken = String(FBSDKAccessToken.currentAccessToken())
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileMenu.hidden = true

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
                print("User id is")
                print(self.userID)
                
                let user : User = AWSService().loadUser(self.userID)
                self.userName = user.userName
                
            }
        })
        
    }
    
    func profileView() {
    
        if (self.toggleState == 0){
            self.toggleState = 1
        profileMenu = UIView(frame: CGRect(x: 0, y: 0, width: (collectionView?.frame.maxX)!, height: ((collectionView?.bounds.height)!)))
        //profileMenu.backgroundColor = UIColor(patternImage: UIImage(named: "Background_Gradient")!)
        profileMenu.backgroundColor = UIColor(red: 0.3216, green: 0.3294, blue: 0.3137, alpha: 1.0)
        let backgroundImage = UIImageView(frame: CGRect(x: 0, y: 0, width: (collectionView?.frame.maxX)!, height: ((collectionView?.bounds.height)!)))
        backgroundImage.image = UIImage(named: "Background_Gradient")
        profileMenu.addSubview(backgroundImage)
      
        profileMenu.tag = 100
        
        let profileLabel = UILabel(frame: CGRect(x: 0, y: 0, width: profileMenu.frame.width, height: profileMenu.frame.height / 5))
        
        let myFriendsLabel = UILabel(frame: CGRect(x: 0, y: profileMenu.frame.height / 3, width: profileMenu.frame.width, height: profileMenu.frame.height / 10))
        
        let moreLabel = UILabel(frame: CGRect(x: 0, y: profileMenu.frame.height / 3 + myFriendsLabel.frame.height, width: profileMenu.frame.width, height: profileMenu.frame.height / 10))
        
            let fetchRequest = NSFetchRequest(entityName: "Users")
            fetchRequest.predicate = NSPredicate(format: "id= %@", self.userID)
            
            let user = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
            let userName = user![0].valueForKey("user_name")
            let score = user![0].valueForKey("score")
            
            let medalImage : UIImage = getRankMedal(Int(score! as! NSNumber))
            
            
            let nameLabel = UITextField(frame: CGRectMake(profileLabel.frame.width / 4, profileLabel.frame.height / 3, profileLabel.frame.width * (3/4), profileLabel.frame.height / 4))
            nameLabel.text = userName as! String
            
            nameLabel.textColor = UIColor.whiteColor()
            profileLabel.addSubview(nameLabel)
            
            let medalLabel = UIImageView(frame: CGRectMake(15, profileLabel.frame.height / 3, profileLabel.frame.width / 5, profileLabel.frame.height / 2 + 10))
            medalLabel.image = medalImage
            profileLabel.addSubview(medalLabel)
            
            let scoreLabel = UITextField(frame: CGRectMake(profileLabel.frame.width / 4, profileLabel.frame.height * (2/3), profileLabel.frame.width * (3/4), profileLabel.frame.height / 4))
            
            scoreLabel.text = String(score!)
            scoreLabel.textColor = UIColor.whiteColor()
            profileLabel.addSubview(scoreLabel)
            
            let topFriendsBorder = CALayer()
            topFriendsBorder.frame = CGRectMake(0, 0, myFriendsLabel.bounds.size.width, 1)
            topFriendsBorder.backgroundColor = UIColor.darkGrayColor().CGColor
            myFriendsLabel.layer.addSublayer(topFriendsBorder)
            let myFriendsTextLabel = UITextField(frame: CGRectMake(15, myFriendsLabel.frame.height / 4, myFriendsLabel.frame.width * (3/4), myFriendsLabel.frame.height / 2))
            myFriendsTextLabel.text = "My VIP"
            myFriendsTextLabel.textColor = UIColor.whiteColor()
            myFriendsTextLabel.font = UIFont(name: "Helvetica Neue", size: 20)
            myFriendsLabel.addSubview(myFriendsTextLabel)
            
            let topMoreBorder = CALayer()
            topMoreBorder.frame = CGRectMake(0, 0, myFriendsLabel.bounds.size.width, 1)
            topMoreBorder.backgroundColor = UIColor.darkGrayColor().CGColor
            moreLabel.layer.addSublayer(topMoreBorder)
            let moreTextLabel = UITextField(frame: CGRectMake(15, moreLabel.frame.height / 4, moreLabel.frame.width * (3/4), moreLabel.frame.height / 2))
            moreTextLabel.text = "More..."
            moreTextLabel.textColor = UIColor.whiteColor()
            moreTextLabel.font = UIFont(name: "Helvetica Neue", size: 20)
            moreLabel.addSubview(moreTextLabel)
            
          
            nameLabel.font = UIFont(name: "Helvetica Neue", size: 18)
            scoreLabel.font = UIFont(name: "Helvetica Neue", size: 14)

            profileMenu.addSubview(profileLabel)
            profileMenu.addSubview(myFriendsLabel)
            profileMenu.addSubview(moreLabel)
            self.view.addSubview(self.profileMenu)
            self.profileMenu.hidden = false
        
        }
        
            
    

        
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var user = AWSService().loadUser(userID, newUserName: "")
        var imagesArr = [Image]()
        var fetchRequest = NSFetchRequest(entityName: "Entity")
        let placesViewController = PlacesViewController()
        if(self.displayPlacesAlbum){
            imagesArr = placesViewController.getImagesForGroup(self.chosenAlbumLocation, user: user)
            print(fetchRequest)
        }
//        let locations = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        var count = 0
        self.previousLocationName = ""
        for image in imagesArr{
            if(self.previousLocationName != image.placeTitle || !self.placesToggle || self.displayPlacesAlbum){
                count=count+1
                self.previousLocationName = image.placeTitle
            }
        }
//        if let locations = locations{
//            for loc in locations{
//                let titleData: AnyObject? = loc.valueForKey("title")
//                let title = titleData as? String
//                if(self.previousLocationName != title || !self.placesToggle || self.displayPlacesAlbum){
//                    count=count+1
//                    self.previousLocationName = title!
//                }
//            }
//        }
        self.previousLocationName = ""
        print(count)
        return count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var user = AWSService().loadUser(userID, newUserName: "")
        var imageArr = [Image]()
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as UICollectionViewCell
        cell.backgroundColor = UIColor.yellowColor()
        var fetchRequest = NSFetchRequest(entityName: "Entity")
        cell.backgroundColor = UIColor.blackColor()

        let placesViewController : PlacesViewController = PlacesViewController()
        if (self.placesToggle && !self.displayPlacesAlbum){
            imageArr = placesViewController.getGroupedImages()
        }else if(self.placesToggle && self.displayPlacesAlbum){
            imageArr = placesViewController.getImagesForGroup(self.chosenAlbumLocation, user: user)
        }else if (hotToggle == 1){
            imageArr = (imageArr as NSArray).sortedArrayUsingDescriptors([
                NSSortDescriptor(key: "totalScore", ascending: false)
                ]) as! [Image]
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "upvotes", ascending: false)]
        }else{
            imageArr = (imageArr as NSArray).sortedArrayUsingDescriptors([
                NSSortDescriptor(key: "totalScore", ascending: false)
                ]) as! [Image]
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
        }
        let locations = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        idArray = []
        var imageArray : [UIImage] = []
        var upVoteArray : [Int] = []
        for img in imageArr{
            let titleData = img.placeTitle
            if(self.previousLocationName != title || !self.placesToggle || self.displayPlacesAlbum){
                let imageID = img.imageID
                self.previousLocationName = titleData
                idArray.append(imageID)
                //Retrieving the image file from S3 example
                let imgData = AWSService().getImageFromUrl(String(imageID) + "_" + self.previousLocationName)
                imageArray.append(imgData)
            }
        }
        
        
//        if let locations = locations{
//            for loc in locations{
//                let titleData: AnyObject? = loc.valueForKey("title")
//                let title = titleData as? String
//                if(self.previousLocationName != title || !self.placesToggle || self.displayPlacesAlbum){
//                    let idData : AnyObject? = loc.valueForKey("id")
//                    let imageId = idData as? Int
//                    self.previousLocationName = title!
//                    idArray.append(imageId!)
//                    let imageData: AnyObject? = loc.valueForKey("imageData")
//                    var imgData = UIImage(data: (imageData as? NSData)!)
//                    //Retrieving the image file from S3 example
//                    //imgData = AWSService().getImageFromUrl(String(imageId) + "_" + self.previousLocationName)
//                    imageArray.append(imgData!)
//
//
//                    let upVoteData : AnyObject? = loc.valueForKey("upvotes")
//                    let upVotes = upVoteData as? Int
//                    upVoteArray.append(upVotes!)
//                    
//                }
//            }
//        }
        let imageButton = UIButton(frame: CGRectMake(0, 0, CGFloat(imgWidth), CGFloat(imgHeight)))
        imageButton.setImage(imageArray[indexPath.row], forState: .Normal)

        
        imageButton.userInteractionEnabled = true
        
        if (self.placesToggle){
            let albumImageView = UIImageView(frame: CGRectMake(imageButton.frame.width * (0.8), imageButton.frame.height * 0.8,  imageButton.frame.width * 0.15, imageButton.frame.height * 0.2));
            let albumImage = UIImage(named : "album2")
            albumImageView.image = albumImage
            imageButton.addSubview(albumImageView)
        }
        
        
        
      
        
        print(imageButton.layer)
        let layer = imageButton.layer
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowOffset = CGSize(width: 0, height: 20)
        layer.shadowOpacity = 0.4
        layer.shadowRadius = 5
        
        
        cell.addSubview(imageButton)
        return cell
    }
    
    func collectionView(collection: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath){
        if (!self.placesToggle || self.displayPlacesAlbum){
            viewPost(idArray[indexPath.row])
        }else{
            displayImagesForAlbum(idArray[indexPath.row])
        }
       
    }
    
    func displayImagesForAlbum(id: String){
        var image : Image = AWSService().loadImage(id)
        self.chosenAlbumLocation = image.placeTitle
//        var fetchRequest = NSFetchRequest(entityName: "Entity")
//        fetchRequest.predicate = NSPredicate(format: "id= %i", sender.tag)
//        let images = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
//        if let images = images{
//            for img in images{
//                let title: AnyObject? = img.valueForKey("title")
//                
//            }
//        }
        self.displayPlacesAlbum = true
        self.collectionView?.reloadData()
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

    
    func viewPost(id : String){
        self.performSegueWithIdentifier("viewPost", sender: id)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print(segue.identifier)
        if segue.identifier == "viewPost" {
            var image : Image = AWSService().loadImage(String(sender))
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
                        let caption : AnyObject? = img.valueForKey("caption")
                        let userName : AnyObject? = img.valueForKey("userOP")
                        destinationVC.imageUpvotes = (imageUpvotes as? Int)!
                        print(imageID)
                        destinationVC.userName = String(self.userName)
                        destinationVC.userNameOP = (userName as?String)!
                        destinationVC.imageTapped = UIImage(data: (imageData as? NSData)!)!
                        destinationVC.imageID = (imageID as? Int)!
                        destinationVC.imageTitle = (imageTitle as? String)!
                        destinationVC.caption = (caption as? String)!
                        destinationVC.userID = Int(self.userID)!
                        
                        
                    }
                }
                let imgData = AWSService().getImageFromUrl(String(image.imageID) + "_" + self.previousLocationName)
                destinationVC.imageUpvotes = image.totalScore
                destinationVC.userName = String(self.userName)
                destinationVC.userNameOP = (userName as?String)!
                destinationVC.imageTapped = imgData
                //destinationVC.imageID = image.imageID
                destinationVC.imageTitle = image.placeTitle
                destinationVC.caption = image.caption
                destinationVC.userID = Int(self.userID)!
            }
        }else if segue.identifier == "PickLocation"{
            
            if let destinationVC = segue.destinationViewController as? PickLocationController{
                
                destinationVC.locations = 1
                destinationVC.userName = userName
            }
        }else if segue.identifier == "login"{
            if let destinationVC = segue.destinationViewController as? FBLoginController{
                destinationVC.locations = 1
            }
        }
    }
    
    func getRankMedal(score : Int) -> UIImage{
        let score = 750
        var medal : UIImage
        if score < 100{
            medal = UIImage(named: "Novice")!
        }else if score >= 100 && score < 500{
            medal = UIImage(named: "Regular")!
        }else if score >= 500 && score < 1000{
            medal = UIImage(named: "Legend")!
        }else if score >= 1000 && score < 2500{
            medal = UIImage(named: "Legend")!
        }else {
            medal = UIImage(named: "Myth")!
        }
        
        return medal
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



