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




var appDel = (UIApplication.shared.delegate as! AppDelegate)
var context:NSManagedObjectContext = appDel.managedObjectContext!
var upVoteInc : CGFloat = 5
var imageUpvotes = UILabel(frame: CGRect(x: 150, y: upVoteInc, width: 30, height: 25))
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
    @IBOutlet weak var activityLoader: UIActivityIndicatorView!

    
    var messageFrame = UIView()
    var stringLabel = UILabel()
    var activityIndicator = UIActivityIndicatorView()
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
    var user = User()
    var placesToggle = false
    var displayPlacesAlbum = false
    var chosenAlbumLocation = ""
    var previousLocationName = ""
    var idArray : [String] = []
    var fbUserID = DispatchGroup()
    var awsUser = DispatchGroup()
    var imageArrLength = 0
    var imageArr = [Image]()
    var uiImageArr = [UIImage]()
    var doneLoading = false
    var chosenImage = UIImage()
    var chosenImageObj = Image()
    var sort = false
    typealias FinishedDownloaded = () -> ()
    
    func tabBar(_ tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        if (item.tag == 1){
            self.placesToggle = false
            self.displayPlacesAlbum = false
            //self.collectionView?.reloadData()
        }else if (item.tag == 2){
            
        }else if (item.tag == 3){
            capVideo()
        }else if (item.tag == 4){
            
        }else if (item.tag == 5){
            //profileView()
        }
    }
    
    
    @IBOutlet weak var sortBtn: UIButton!
    @IBAction func toggleSort(_ sender: AnyObject) {
        if (self.hotToggle == 0){
            sortBtn.setTitle("Popular", for: UIControlState())
            getHotImages()
        }else{
            sortBtn.setTitle("Recent", for: UIControlState())
            getRecentImages()
        }
    }
    
    func getHotImages() {
        self.sort = true
        self.hotToggle = 1
        collectionView?.reloadData()
        
    }
    
    func getRecentImages() {
        self.sort = true
        self.toggleState = 0
        self.hotToggle = 0
        
        collectionView?.reloadData()
    }
    
    @IBOutlet weak var imagesTypeBtn: UIButton!

    @IBAction func getPlacesView(_ sender: AnyObject) {
        if (!self.placesToggle){
            self.placesToggle = true
            imagesTypeBtn.setTitle("Places", for: UIControlState())
        }else{
            imagesTypeBtn.setTitle("People", for: UIControlState())
            self.placesToggle = false
        }
        determineQuery()
    }
    
    override func viewDidAppear(_ animated: Bool) {

        super.viewDidAppear(animated)
        
        self.view.isHidden = false
        if (FBSDKAccessToken.current() == nil)
        {
            print("is nil")
            self.performSegue(withIdentifier: "login", sender: nil)
        }else{
            self.accessToken = String(describing: FBSDKAccessToken.current())
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        progressBarDisplayer("Loading", true)
        profileMenu.isHidden = true
        
        self.view.isHidden = true
        // Do any additional setup after loading the view, typically from a nib.
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        collectionView?.dataSource = self
        collectionView!.delegate = self
        collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        let nibname = UINib(nibName: "Cell", bundle: nil)
        collectionView!.register(nibname, forCellWithReuseIdentifier: "Cell")
        collectionView!.register(NSClassFromString("GalleryCell"),forCellWithReuseIdentifier:"CELL");

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
        let barViewControllers = self.tabBarController?.viewControllers
        let svc = barViewControllers![2] as! PickLocationController
        
        //dispatch_group_enter(fbUserID)
        retrieveUserID({(result)->Void in
            self.userID = result
            AWSService().loadUser(self.userID,completion: {(result)->Void in
                self.user = result
                svc.user = result
                print("user id is ")
                print(self.user?.userID)
            })
            
        })
        determineQuery()
       
        //self.user = AWSService().loadUser(self.userID)


    }
    
    func retrieveUserID(_ completion:@escaping (_ result: String)->Void){
        var id = ""
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, first_name, gender, age_range"])
        graphRequest.start(completionHandler: { (connection, result, error) -> Void in
            
            if ((error) != nil)
            {
                // Process error
                print("Error: \(error)")
                
            }else{
                let userID = (result as AnyObject).object(forKey: "id") as! String
                completion(userID)
                
            }
            
        })
        
        
    }
    

    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        if (self.imageArrLength == 0){
            return 1
        }else{
            return self.imageArrLength
        }
//        var imagesArr = [Image]()
//        let placesViewController = PlacesViewController()
//        if (self.placesToggle && !self.displayPlacesAlbum){
//            placesViewController.getGroupedImages({(result)->Void in
//                imagesArr = result
//            })
//        }else if(self.placesToggle && self.displayPlacesAlbum){
//            placesViewController.getImagesForGroup(self.chosenAlbumLocation, user: user, completion: {(result)->Void in
//                imagesArr = result
//            })
//        }
//        
//        self.previousLocationName = ""
//        for image in imagesArr{
//            if(self.previousLocationName != image.placeTitle || !self.placesToggle || self.displayPlacesAlbum){
//                count=count+1
//                self.previousLocationName = image.placeTitle
//            }
//        }
//        self.previousLocationName = ""
//        print(count)
        return 1
    }
    
    func progressBarDisplayer(_ msg:String, _ indicator:Bool ) {
        stringLabel = UILabel(frame: CGRect(x: 50, y: 0, width: 175, height: 50))
        stringLabel.text = msg
        stringLabel.textColor = UIColor.white
        messageFrame = UIView(frame: CGRect(x: self.collectionView!.frame.midX - 90, y: self.collectionView!.frame.midY - 100, width: 180, height: 50))
        messageFrame.layer.cornerRadius = 15
        messageFrame.backgroundColor = UIColor(white: 0, alpha: 0.7)
        if indicator {
            activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
            activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            activityIndicator.startAnimating()
            messageFrame.addSubview(activityIndicator)
        }
        messageFrame.addSubview(stringLabel)
        self.collectionView!.addSubview(messageFrame)
    }
    
    func determineQuery(){
        let placesViewController : PlacesViewController = PlacesViewController()
        if (self.placesToggle && !self.displayPlacesAlbum){
            var groupedArr = [Image]()
            placesViewController.getImages(completion: {(result)->Void in
                let imgArr = result
                
                let sortedArray = (imgArr as NSArray).sortedArray(using: [
                    NSSortDescriptor(key: "placeTitle", ascending: false),
                    NSSortDescriptor(key: "totalScore", ascending: false)
                    ]) as! [Image]
                var found = false
                for img in sortedArray{
                    found = false
                    for i in 0 ..< groupedArr.count{
                        if (img.placeTitle == groupedArr[i].placeTitle){
                            found = true
                            break
                        }
                    }
                    if (!found){
                        groupedArr.append(img)
                    }
                }
                self.sort = false
                self.uiImageArr = []
                self.idArray = []
                self.imageArr = []
                self.imageArr = result
                self.imageArrLength = groupedArr.count
                self.doneLoading = true
                DispatchQueue.main.async(execute: {
                    self.collectionView!.reloadData()
                })
                
            })
        }else if(self.placesToggle && self.displayPlacesAlbum){
            placesViewController.getImagesForGroup(placeName: self.chosenAlbumLocation, user: user!, completion: {(result)->Void in
                self.sort = false
                self.idArray = []
                self.uiImageArr = []
                self.imageArr = []
                self.imageArr = result
                self.imageArrLength = self.imageArr.count
                self.doneLoading = true
                DispatchQueue.main.async(execute: {
                    self.collectionView!.reloadData()
                })
            })
        }else{
            placesViewController.getImages(completion: {(result)->Void in
                self.sort = false
                self.uiImageArr = []
                self.imageArr = []
                self.idArray = []
                self.imageArr = result
                self.imageArrLength = self.imageArr.count
                self.doneLoading = true
                self.imageArrLength = self.imageArr.count
                DispatchQueue.main.async(execute: {
                self.collectionView!.reloadData()
                })
            })
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        
        self.uiImageArr = []
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as UICollectionViewCell
        cell.backgroundColor = UIColor.yellow
        cell.backgroundColor = UIColor.black
        
        var imageArray : [UIImage] = []
    
        if (self.doneLoading){
        if (hotToggle == 1){
            self.imageArr = (self.imageArr as NSArray).sortedArray(using: [
                NSSortDescriptor(key: "totalScore", ascending: false)
                ]) as! [Image]
        }else{
            
            self.imageArr = (self.imageArr as NSArray).sortedArray(using: [
                NSSortDescriptor(key: "timePosted", ascending: false)
                ]) as! [Image]
        }
        idArray = []
        if (!self.sort){
            var upVoteArray : [Int] = []
            for img in self.imageArr{
                let titleData = img.placeTitle
                if(self.previousLocationName != title || !self.placesToggle || self.displayPlacesAlbum){
                    let imageID = img.imageID
                    self.previousLocationName = titleData
                    idArray.append(imageID)
                    //Retrieving the image file from S3 example
                    AWSService().getImageFromUrl(String(imageID), completion: {(result)->Void in
                    
                        self.uiImageArr.append(result)
                        //self.collectionView?.reloadData()
                    
                    })
                
                }
            }
        }
            
        if (self.uiImageArr.count > 0){
            if (self.placesToggle){
                imgHeight = 240
                imgWidth = 240
                noColumns = 1
            }else{
                imgHeight = 160
                imgWidth = 120
                noColumns = 2
            }
        let imageButton = UIButton(frame: CGRect(x: 0, y: 0, width: CGFloat(imgWidth), height: CGFloat(imgHeight)))
        imageButton.setImage(self.uiImageArr[(indexPath as NSIndexPath).row], for: UIControlState())

            let titleView = UILabel(frame: CGRect(x: 0, y: imageButton.frame.height * 0.9, width: imageButton.frame.width, height: imageButton.frame.height * 0.1))
            titleView.text = self.imageArr[(indexPath as NSIndexPath).row].placeTitle
            titleView.textColor = UIColor.white
            titleView.backgroundColor = UIColor.black
            titleView.font = UIFont (name: "Helvetica Neue", size: 12)
            imageButton.addSubview(titleView)
        imageButton.isUserInteractionEnabled = true
            imageButton.layer.masksToBounds = true
        
        if (self.placesToggle){
            let albumImageView = UIImageView(frame: CGRect(x: imageButton.frame.width * (0.8), y: imageButton.frame.height * 0.8,  width: imageButton.frame.width * 0.15, height: imageButton.frame.height * 0.2));
            let albumImage = UIImage(named : "album2")
            albumImageView.image = albumImage
            imageButton.addSubview(albumImageView)
        }
        
        
        //
            let imagePressed :Selector = #selector(ViewController.imagePressed(_:))
        let tap = UITapGestureRecognizer(target: self, action: imagePressed)
        tap.numberOfTapsRequired = 1
        imageButton.addGestureRecognizer(tap)
        print(imageButton.layer)
        let layer = imageButton.layer
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 20)
        layer.shadowOpacity = 0.4
        layer.shadowRadius = 5
            layer.masksToBounds = true
            imageButton.clipsToBounds = true
        
        
        cell.addSubview(imageButton)
        cell.layer.cornerRadius = 5
            cell.layer.masksToBounds = true
            cell.clipsToBounds = true
        }
        }
        self.messageFrame.removeFromSuperview()
        return cell
    }
    
    @IBAction func imagePressed(_ sender: UITapGestureRecognizer){
        let tapLocation = sender.location(in: self.view)
        let indexPath = self.collectionView?.indexPathForItem(at: tapLocation)
        if (!self.placesToggle || self.displayPlacesAlbum){
            self.chosenImageObj = self.imageArr[(indexPath! as NSIndexPath).row]
            self.chosenImage = self.uiImageArr[(indexPath! as NSIndexPath).row]
            self.performSegue(withIdentifier: "viewPost", sender: nil)
        }else{
            displayImagesForAlbum(self.imageArr[(indexPath! as NSIndexPath).row])
        }
    }
    
    func collectionView(_ collection: UICollectionView, didSelectItemAt indexPath: IndexPath){

       
    }
    
    func displayImagesForAlbum(_ img: Image){

        self.chosenAlbumLocation = img.placeTitle
        self.displayPlacesAlbum = true
        determineQuery()
//        var fetchRequest = NSFetchRequest(entityName: "Entity")
//        fetchRequest.predicate = NSPredicate(format: "id= %i", sender.tag)
//        let images = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
//        if let images = images{
//            for img in images{
//                let title: AnyObject? = img.valueForKey("title")
//                
//            }
//        }

    }
    
    //begin auto layout code
    
    //set size of each square cell to imgSize
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if (self.placesToggle){
            imgHeight = 240
            imgWidth = 240
            noColumns = 1
        }else{
            imgHeight = 160
            imgWidth = 120
            noColumns = 2
        }
        let size = CGSize(width: imgWidth, height: imgHeight)
        return size
    }
    
    //calculate offset based on screensize, number of columns, and size of cell then use it to apply the inset
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        var offset = CGFloat(0.0)
        if (noColumns == 2){
            offset = (screenWidth - CGFloat(noColumns*imgWidth)) / CGFloat(noColumns+1)
        }else{
            offset = 25
        }
        let sectionInset = UIEdgeInsets(top: offset/2, left: offset, bottom: offset/2, right: offset)
        return sectionInset
    }
    

    //calculate offset based on screensize, number of columns, and size of cell then use it to set space between lines
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat{
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        var offset = CGFloat(0.0)
        if (noColumns == 2){
            offset = (screenWidth - CGFloat(noColumns*imgWidth)) / CGFloat(2*(noColumns+1))
        }else{
            offset = 25

        }
        return offset
    }
    

    //end auto layout code
    
    //get user location function
    //all you need to do to get user location is locationManager.startUpdatingLocation()
    //it will start getting the users location in the background 
    //call it when they open the camera to take a picture so it has a few seconds to settle
    //store userLocation in the database once picture is taken (error check to make sure it got a location)
    //call locationManager.stopUpdatingLocation once location has been stored and reset locationUpdated to false

    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations[0].coordinate
        print("\(userLocation.latitude) Degrees Latitude, \(userLocation.longitude) Degrees Longitude")
        locationUpdated = true
    }
    
    
    @IBAction func capVideo() {
        
        
        self.performSegue(withIdentifier: "PickLocation", sender: 1)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print(segue.identifier)
        if segue.identifier == "viewPost" {
            let image = Image()
          
            if let destinationVC = segue.destination as? viewPostController{
               
                destinationVC.imageTapped = self.chosenImage
                print("IMAGE ID: " + (image?.imageID)!)
                destinationVC.imageObj = self.chosenImageObj
                destinationVC.imageID = (self.chosenImageObj?.imageID)!
            }
            print("IMAGE ID: " + (image?.imageID)!)
            
            
        }else if segue.identifier == "PickLocation"{
            
            if let destinationVC = segue.destination as? PickLocationController{
                
                destinationVC.locations = 1
                destinationVC.userName = userName
            }
        }else if segue.identifier == "login"{
            if let destinationVC = segue.destination as? FBLoginController{
                destinationVC.locations = 1
            }
        }
    }
    
    func getRankMedal(_ score : Int) -> UIImage{
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

    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //self.collectionView?.reloadData()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}



