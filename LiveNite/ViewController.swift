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
var imgWidth = 160
var imgHeight = 200






class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, CLLocationManagerDelegate{
    
    @IBOutlet weak var scroller: UIScrollView!

    @IBOutlet
    var tableView : UITableView!
    

    @IBOutlet var collectionView: UICollectionView?



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
    var imageArrTemp = [Image]()
    var uiImageArr = [UIImage]()
    var doneLoading = false
    var chosenImage = UIImage()
    var titleCountArr = [Int]()
    var chosenImageObj = Image()
    var sort = false
    var uiImageDict = [String:UIImage]()
    var uiImageDictTemp = [String:UIImage]()
    var sortedUIImageArray = [UIImage]()
    var altNavBar = UIView()
    var arrayEmpty = false
    var loggingIn = false
    var tryAgainButton = UILabel()
    var emptyArrayLabel = UILabel()
    typealias FinishedDownloaded = () -> ()
    
    

    
    func handleRefresh(_ refreshControl: UIRefreshControl){
        AWSService().loadUser(self.userID,completion: {(result)->Void in
            self.user = result
            self.determineQuery()
            
        })
    }
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        return refreshControl
    }()
    
    func tabBar(_ tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        if (item.tag == 1){
            self.placesToggle = false
            self.displayPlacesAlbum = false
        }else if (item.tag == 2){
            
        }else if (item.tag == 3){
            capVideo()
        }else if (item.tag == 4){
            
        }else if (item.tag == 5){
            //profileView()
        }
    }
    
    
    @IBOutlet weak var sortBtn: UIButton!
    @IBOutlet weak var topNavBar: UIView!
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
        determineSort()
        self.collectionView?.reloadData()
        
    }
    
    func getRecentImages() {
        self.sort = true
        self.toggleState = 0
        self.hotToggle = 0
        determineSort()
        collectionView?.reloadData()
    }
    
    @IBOutlet weak var imagesTypeBtn: UIButton!

    @IBAction func getPlacesView(_ sender: AnyObject) {
        progressBarDisplayer("Loading", true)
        
        self.view.isUserInteractionEnabled = false
        if (!self.placesToggle){
            self.placesToggle = true
        imagesTypeBtn.setImage(UIImage(named:"PlacesSelect"), for: UIControlState.normal)
        }else{
            imagesTypeBtn.setImage(UIImage(named:"PeopleSelect"), for: UIControlState.normal)
            self.placesToggle = false
        }
        determineQuery()
    }
    
    override func viewWillAppear(_ animated: Bool){
        self.navigationController?.setNavigationBarHidden(true , animated: animated)
        super.viewWillAppear(animated)
    }
    override func viewWillDisappear(_ animated: Bool){
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }
    
    @IBAction func searchPosts(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "searchPosts", sender: sender.tag)
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
            //setupHomeScreen()
            if (self.loggingIn){
                determineQuery()
                self.loggingIn = false
            }

        }
        

    }
    
    func setupHomeScreen(){
        self.collectionView?.backgroundView = UIImageView(image: UIImage(named: "backgroundimg"))
        if (self.imageArr.count == 0){
            progressBarDisplayer("Loading", true)
        }
        self.collectionView?.alwaysBounceVertical = true
        profileMenu.isHidden = true
        //self.view.isHidden = true
        // Do any additional setup after loading the view, typically from a nib.
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        collectionView?.dataSource = self
        collectionView!.delegate = self
        collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        let nibname = UINib(nibName: "Cell", bundle: nil)
        collectionView!.register(nibname, forCellWithReuseIdentifier: "Cell")
        collectionView!.register(NSClassFromString("GalleryCell"),forCellWithReuseIdentifier:"CELL");
        self.refreshControl.tintColor = UIColor.white
        collectionView?.addSubview(self.refreshControl)
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
        locationManager.startUpdatingLocation()


        self.collectionView?.frame = CGRect(x: 0, y: self.topNavBar.frame.height, width: self.view.frame.width, height: self.view.frame.height * 0.9)
        let barViewControllers = self.tabBarController?.viewControllers
        let svc = barViewControllers![2] as! PickLocationController
        retrieveUserID({(result)->Void in
            self.userID = result
            AWSService().loadUser(self.userID,completion: {(result)->Void in
                self.user = result
                svc.user = result
                print("user id is ")
                print(self.user?.userID)
                self.determineQuery()
                  AWSService().getOpenNotifications(userName: (self.user?.userName)!,completion: {(result)->Void in
                            DispatchQueue.main.async(execute: {
                                var count = result.count
                                if (count > 0){
                                    self.tabBarController?.tabBar.items?[3].badgeValue = String(count)
                                }
                            })

                })
            })
            
        })

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupHomeScreen()
        self.view.bringSubview(toFront: topNavBar)
          //dispatch_group_enter(fbUserID)



       
       
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
                let data:[String:AnyObject] = result as! [String: AnyObject]
                let userID = data["id"] as? String
                self.userID = userID!
                completion(userID!)
                
            }
            
        })
        
        
    }
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.characters.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (self.arrayEmpty){
            return 1
        }else{
            return self.imageArr.count
        }
    }
    
    @IBOutlet weak var sortButton: UIButton!
    @IBOutlet weak var searchBtn: UIButton!
    @IBOutlet weak var imgTypeBtn: UIButton!
    func switchNavBar(albumView:Bool){
        self.altNavBar = UIView(frame: CGRect(x: 0, y: 0, width: self.topNavBar.frame.width, height: self.topNavBar.frame.height))
        altNavBar.backgroundColor = hexStringToUIColor(hex: "#3869CB")
        let exitButton = UIButton(frame: CGRect(x: self.topNavBar.frame.width * 0.1, y: self.topNavBar.frame.height * 0.1, width: self.topNavBar.frame.width * 0.1, height: self.topNavBar.frame.height * 0.8))
        var placeTitleLabel = UILabel(frame: CGRect(x: self.topNavBar.frame.width * 0.4, y: self.topNavBar.frame.height * 0.15, width: self.topNavBar.frame.width * 0.6, height: self.topNavBar.frame.height * 0.8))
       
        placeTitleLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 16.0)
        altNavBar.isHidden = true

        
        let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
        spacer.width = -15

        DispatchQueue.main.async(execute: {
            

            if (albumView){

                
                self.sortBtn.isHidden = false
                self.searchBtn.isHidden = false
                self.imgTypeBtn.isHidden = false
                self.topNavBar.isHidden = false
                self.altNavBar.bringSubview(toFront: placeTitleLabel)
                placeTitleLabel.text = ""
                self.view.bringSubview(toFront: self.topNavBar)
                self.altNavBar.isHidden = true
               
                
               
                
            }else{
                let backButton = UIButton(frame: CGRect(x:0, y: 0, width: 70.0, height: 70.0))
                let backImage = UIImage(named: "backBtn")
                backButton.setImage(backImage, for: UIControlState.normal)
                //backButton.titleEdgeInsets = UIEdgeInsetsMake(5.0, 20.0, 10.0, 0.0)
                backButton.addTarget(self, action: #selector(self.backToAlbumView(_:)), for: .touchUpInside)
                self.topNavBar.isHidden = true
                self.altNavBar.addSubview(backButton)
                self.topNavBar.bringSubview(toFront: backButton)
                self.altNavBar.isHidden = false
                placeTitleLabel.textColor = UIColor.white
                placeTitleLabel.text = self.chosenAlbumLocation
                
                placeTitleLabel.center.x = self.view.center.x
                placeTitleLabel.textAlignment = NSTextAlignment.center

                self.altNavBar.addSubview(placeTitleLabel)
                self.view.addSubview(self.altNavBar)
            
                
            }
        })

        
    }
    func reloadCollectionView(){
        self.arrayEmpty = false
        progressBarDisplayer("Loading", true)
        self.determineQuery()
    }
    
    func backToAlbumView(_ sender: UIButton!){
        self.topNavBar.isHidden = false
        self.altNavBar.isHidden = true
        self.placesToggle = true
        self.displayPlacesAlbum = false
        self.uiImageDict = self.uiImageDictTemp
        self.imageArr = self.imageArrTemp
        self.imageArrLength = self.imageArr.count
        self.doneLoading = true
        self.collectionView?.reloadData()
    }
    
    func progressBarDisplayer(_ msg:String, _ indicator:Bool ) {

        if indicator {


            self.activityIndicator.frame = CGRect(x:self.view.frame.midX - 50, y: self.view.frame.midY - 100, width: 100, height: 100)
            self.activityIndicator.startAnimating()
            self.collectionView?.addSubview(self.activityIndicator)
            

        }
    }
    
    func determineQuery(){
        let placesViewController : PlacesViewController = PlacesViewController()
        if (self.placesToggle && !self.displayPlacesAlbum){
            var groupedImageDictionary = [String: AnyObject]()
           
            var groupedArr = [Image]()
            placesViewController.getImages(user: self.user!, completion: {(result)->Void in
                let imgArr = result
                if (self.imageArr.count == 0){
                    self.arrayEmpty = true
                }else{
                    self.arrayEmpty = false
                }
                let sortedArray = (imgArr as NSArray).sortedArray(using: [
                    NSSortDescriptor(key: "placeTitle", ascending: false),
                    NSSortDescriptor(key: "totalScore", ascending: false)
                    ]) as! [Image]
                var found = false
                var titleCount = 0
                var previousTitle = ""
                for img in sortedArray{
                    if (img.placeTitle != previousTitle && previousTitle != ""){
                        groupedArr[groupedArr.count - 1].groupedCount = titleCount
                        titleCount = 0
                    }
                    titleCount += 1
                    previousTitle = img.placeTitle
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
                if (titleCount != 0){
                    groupedArr[groupedArr.count - 1].groupedCount = titleCount
                }
                self.sort = false
                self.uiImageArr = []
                self.idArray = []
                self.imageArr = []
                self.imageArr = groupedArr

                self.imageArrLength = groupedArr.count
                self.doneLoading = true
                
                self.determineSort()
                for img in self.imageArr{
                    AWSService().getImageFromUrl(String(img.imageID), bucket: "liveniteimages", completion: {(result)->Void in
                        self.uiImageArr.append(result)
                        if self.uiImageArr.count == self.imageArr.count{
                            
                            DispatchQueue.main.async(execute: {
                                self.uiImageDict = self.createUIImageDict()
                                self.uiImageDictTemp = self.uiImageDict
                                self.imageArrTemp = self.imageArr
                                self.refreshControl.endRefreshing()
                                
                                self.view.isUserInteractionEnabled = true
                                    
                                
                                self.collectionView!.reloadData()
                            })
                            
                        }
                    })
                }
                
            })
        }else if(self.placesToggle && self.displayPlacesAlbum){
            placesViewController.getImagesForGroup(placeName: self.chosenAlbumLocation, user: user!, completion: {(result)->Void in
                self.placesToggle = false
                
                self.sort = false
                self.idArray = []
                self.uiImageArr = []
                self.imageArr = []
                self.imageArr = result
                if (self.imageArr.count == 0){
                    self.arrayEmpty = true
                }else{
                    self.arrayEmpty = false
                }

                self.imageArrLength = self.imageArr.count
                self.doneLoading = true
                self.determineSort()
                for img in self.imageArr{
                    AWSService().getImageFromUrl(String(img.imageID), bucket: "liveniteimages", completion: {(result)->Void in
                        self.uiImageArr.append(result)
                        if self.uiImageArr.count == self.imageArr.count{
                            self.switchNavBar(albumView: false)
                            
                            DispatchQueue.main.async(execute: {
                                self.uiImageDict = self.createUIImageDict()
                                self.refreshControl.endRefreshing()
                                
                                self.view.isUserInteractionEnabled = true
                                    
                                
                                self.collectionView!.reloadData()
                            })
                            
                        }
                    })
                }
            })
        }else{
            placesViewController.getImages(user: self.user!, completion: {(result)->Void in
                self.sort = false
                self.uiImageArr = []
                self.imageArr = []
                self.idArray = []
                self.imageArr = result
                if (self.imageArr.count == 0){
                    self.arrayEmpty = true
                    self.collectionView!.reloadData()
                }else{
                    self.arrayEmpty = false
                }

                self.imageArrLength = self.imageArr.count
                self.doneLoading = true
                self.imageArrLength = self.imageArr.count
                //write function to determine sort
                //create dictionary with images for sorting
                self.determineSort()
                for img in self.imageArr{
                    AWSService().getImageFromUrl(String(img.imageID), bucket: "liveniteimages", completion: {(result)->Void in
                        self.uiImageArr.append(result)
                        if self.uiImageArr.count == self.imageArr.count{
                            DispatchQueue.main.async(execute: {
            
                               self.uiImageDict = self.createUIImageDict()

                                self.refreshControl.endRefreshing()

                                self.view.isUserInteractionEnabled = true

                                
                                self.collectionView!.reloadData()

                            })
                        }
                    })
                }
                
                
            })
        }
    }
    
    func determineSort(){
        if (self.hotToggle == 1){
            self.imageArr = (self.imageArr as NSArray).sortedArray(using: [
                NSSortDescriptor(key: "totalScore", ascending: false)
                ]) as! [Image]
        }else{
            
            self.imageArr = (self.imageArr as NSArray).sortedArray(using: [
                NSSortDescriptor(key: "timePosted", ascending: false)
                ]) as! [Image]
        }
    
    }
    
//    func determineUIImageSort(){
//
//        
//        var sortedUIImgArray = [UIImage]()
//        
//        
//        for i in 0...self.imageArr.count-1{
//            var imageID = self.imageArr[i].imageID
//            sortedUIImgArray.append(self.uiImageDict[self.imageArr[i].imageID]!)
//        }
//        self.uiImageArr = []
//        self.uiImageArr = sortedUIImgArray
//    }
    
    func createUIImageDict() -> [String: UIImage]{

        var dict = [String: UIImage]()
        for i in 0...self.imageArr.count-1{
            
            dict[self.imageArr[i].imageID] = self.uiImageArr[i]
            
        }
        return dict
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as UICollectionViewCell
        
        cell.backgroundColor = UIColor.clear
    
        if (self.doneLoading && !self.arrayEmpty){

        idArray = []

            
        
            if (self.placesToggle){
                imgHeight = 240
                imgWidth = 240
                noColumns = 1
            }else{
                imgHeight = 200
                imgWidth = 160
                noColumns = 2
            }
        
        let imageButton = UIButton(frame: CGRect(x: 0, y: 0, width: CGFloat(imgWidth), height: CGFloat(imgHeight)))
             imageButton.setImage(nil, for: UIControlState())
            imageButton.setImage(self.uiImageDict[self.imageArr[indexPath.row].imageID], for: UIControlState())
            

            
            //let titleViewContainer = UIView(frame: CGRect(x: 0, y: imageButton.frame.height * 0.85, width: imageButton.frame.width, height: imageButton.frame.height * 0.15))
            let titleView = UILabel(frame: CGRect(x: 0, y: imageButton.frame.height * 0.85, width: imageButton.frame.width, height: imageButton.frame.height * 0.15))
            
            
            titleView.text = " " + self.imageArr[(indexPath as NSIndexPath).row].placeTitle
            titleView.textColor = UIColor.white
            titleView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.5)
            titleView.font = UIFont (name: "HelveticaNeue-Bold", size: 12)
            //titleViewContainer.backgroundColor = UIColor.darkGray.withAlphaComponent(0.4)
            //imageButton.addSubview(titleViewContainer)
            imageButton.addSubview(titleView)
        imageButton.isUserInteractionEnabled = true
            imageButton.layer.masksToBounds = true
        
        if (self.placesToggle){
            let albumImageView = UIView(frame: CGRect(x: imageButton.frame.width * (0.8), y: imageButton.frame.height * 0.7,  width: imageButton.frame.width * 0.15, height: imageButton.frame.height * 0.15));
            albumImageView.layer.cornerRadius = 5
            let albumCount = UILabel(frame: CGRect(x: albumImageView.frame.width * 0.4, y: 0,  width: albumImageView.frame.width, height: albumImageView.frame.height))
            albumCount.text = String(self.imageArr[indexPath.row].groupedCount)
            albumCount.textColor = UIColor.white
            albumImageView.backgroundColor = UIColor.black
            albumImageView.addSubview(albumCount)
            imageButton.addSubview(albumImageView)
        }
        
        
        //
            let imagePressed :Selector = #selector(ViewController.imagePressed(_:))
        let tap = UITapGestureRecognizer(target: self, action: imagePressed)
        tap.cancelsTouchesInView = false
        tap.numberOfTapsRequired = 1
        imageButton.addGestureRecognizer(tap)
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
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
        }else if (doneLoading){
         DispatchQueue.main.async(execute: {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
            self.emptyArrayLabel = UILabel(frame: CGRect(x: 0, y: ((self.collectionView?.frame.height)! / 2) - 75, width: self.view.frame.width, height: 50))
            self.tryAgainButton = UILabel(frame: CGRect(x: 0, y: ((self.collectionView?.frame.height)! / 2) - 50, width: self.view.frame.width, height: 50))
            self.tryAgainButton.text = "Tap to retry"
            self.tryAgainButton.textAlignment = .center
            self.tryAgainButton.textColor = UIColor.white
            self.tryAgainButton.layer.masksToBounds = true

            self.emptyArrayLabel.text = "No posts found"
            self.tryAgainButton.font = UIFont.boldSystemFont(ofSize: 16)
            self.emptyArrayLabel.textColor = UIColor.white
            self.emptyArrayLabel.textAlignment = .center


            cell.addSubview(self.tryAgainButton)
            cell.addSubview(self.emptyArrayLabel)
            })
        }

       
        return cell
    }
    
    @IBAction func imagePressed(_ sender: UITapGestureRecognizer){
        let tapLocation = sender.location(in: self.collectionView)
        let indexPath = self.collectionView?.indexPathForItem(at: tapLocation)
        if (!self.placesToggle || self.displayPlacesAlbum){
            self.chosenImageObj = self.imageArr[(indexPath! as NSIndexPath).row]
            self.chosenImage = self.uiImageDict[self.imageArr[(indexPath?.row)!].imageID]!
            self.performSegue(withIdentifier: "viewPost", sender: nil)
        }else{
            displayImagesForAlbum(self.imageArr[(indexPath! as NSIndexPath).row])
        }
    }
    
    func collectionView(_ collection: UICollectionView, didSelectItemAt indexPath: IndexPath){
        if (self.arrayEmpty){
            self.emptyArrayLabel.removeFromSuperview()
            self.tryAgainButton.removeFromSuperview()
            reloadCollectionView()
        }
       
    }
    
    func displayImagesForAlbum(_ img: Image){

        self.chosenAlbumLocation = img.placeTitle
        self.displayPlacesAlbum = true
        determineQuery()

    }
    
    //begin auto layout code
    
    //set size of each square cell to imgSize
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if (self.placesToggle){
            imgHeight = 240
            imgWidth = 240
            noColumns = 1
        }else if (self.arrayEmpty){
            imgHeight = Int((self.collectionView?.frame.height)!)
            imgWidth = Int(self.collectionView!.frame.width)
            noColumns = 1
        }else{
        
            imgHeight = 200
            imgWidth = 160
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
        locationManager.stopUpdatingLocation()
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
                destinationVC.user = self.user
            }
            print("IMAGE ID: " + (image?.imageID)!)
            
            
        }else if segue.identifier == "PickLocation"{
            
            if let destinationVC = segue.destination as? PickLocationController{
                
                destinationVC.locations = 1
                destinationVC.userName = userName
            }
        }else if segue.identifier == "login"{
            if let destinationVC = segue.destination as? FBLoginController{
                self.loggingIn = true
                destinationVC.locations = 1
                destinationVC.userID = (self.userID)
            }
        }else if segue.identifier == "searchPosts"{
            if let destinationVC = segue.destination as? SearchPostsController{
                destinationVC.uiImageArray = self.uiImageArr
                destinationVC.imageArray = self.imageArr
                destinationVC.user = self.user
            }
        }
    }
    


    
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}



