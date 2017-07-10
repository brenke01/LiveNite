//
//  ProfileController.swift
//  LiveNite
//
//  Created by Kevin on 3/1/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//
import AVFoundation
import SCLAlertView
import AWSDynamoDB

class ProfileController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate, AVCaptureMetadataOutputObjectsDelegate, UICollectionViewDataSource{
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet var QrImageView: UIImageView!
    var qrCodeImage : CIImage!
    var captureSession : AVCaptureSession?
    var videoPreviewLayer : AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    
    @IBOutlet weak var profileInfoContainer: UIView!
    
    @IBOutlet weak var postsButton: UIButton!
    
    @IBOutlet weak var eventsButton: UIButton!
    @IBOutlet weak var profilebkg: UIView!
    var locations = 0
    var locationUpdated = false
    var toggleState = 0
    var hotToggle = 0
    var profileMenu = UIView()
    var accessToken = ""
    var userID = ""
    var user = User()
    var profileForm = ProfileSettingsForm()
    var activityIndicator = UIActivityIndicatorView()
    var editButton = UIBarButtonItem()
    var arrayEmpty = false
    var imageArr = [Image]()
    var uiImageDict = [String:UIImage]()
    var uiImageArr = [UIImage]()
    var chosenImageObj = Image()
    var chosenImage = UIImage()
    var imageUtil = ImageUtil()
    var showEvents = false
    var showPosts = false
    var eventBorder = CALayer()
    var border = CALayer()
    var eventsArr = [Event]()
    var selectedEvent = Event()
    var selectedEventImg = UIImage()
    var tryAgainButton = UILabel()
    var emptyArrayLabel = UILabel()


    
    @IBOutlet weak var profileImg: UIImageView!
    
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var distanceContainer: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var imgView: UIImageView!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.view.isHidden = false
        
    }
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var sliderValue: UISlider!
    
    @IBOutlet weak var pullView: UIView!
    var connectButton : UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeBorders()
        self.showPosts = true
        switchBorder()
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        collectionView?.dataSource = self
        collectionView!.delegate = self
        collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        let nibname = UINib(nibName: "Cell", bundle: nil)
        collectionView!.register(nibname, forCellWithReuseIdentifier: "Cell")
        collectionView!.register(NSClassFromString("GalleryCell"),forCellWithReuseIdentifier:"CELL");
        //profileInfoContainer.isHidden = true
        //profileInfoContainer.backgroundColor = UIColor.clear
        profilebkg.backgroundColor? = UIColor.darkGray.withAlphaComponent(0.5)
        navigationController?.navigationBar.topItem?.title = "Profile"
        scrollView.delegate = self
        profileImg.layer.borderWidth = 2
        profileImg.layer.borderColor = UIColor.white.cgColor
        profileImg.layer.masksToBounds = true
        //profileImg.backgroundColor = UIColor(red: 58/255, green:67/255, blue:96/255, alpha:1)
        navigationController?.navigationBar.tintColor = UIColor.white
        self.editButton = UIBarButtonItem(title: nil, style: .plain, target: self, action: #selector(self.editSettings))
        self.editButton.image = UIImage(named: "editGear")
        self.navigationItem.rightBarButtonItem = self.editButton
        
//        let path = UIBezierPath(roundedRect:profilebkg.bounds,
//                                byRoundingCorners:[.bottomRight, .bottomLeft],
//                                cornerRadii: CGSize(width: 10, height:  10))
//        
//        let maskLayer = CAShapeLayer()
//        
//        maskLayer.path = path.cgPath
//        profilebkg.layer.mask = maskLayer
        
        
        connectButton = UIBarButtonItem(title: nil, style: .plain, target: self, action: #selector(self.connectWithUser))
        connectButton.image = UIImage(named: "connect")
        self.navigationItem.leftBarButtonItem = connectButton
        
        if (self.user?.userID == ""){
            retrieveUserID({(result)->Void in
                self.userID = result
                AWSService().loadUser(self.userID,completion: {(result)->Void in
                    self.user = result
                    DispatchQueue.main.async(execute: {
                        self.progressBarDisplayer("Loading", true)
                        self.loadUserDetail()
                        self.getImages()

                        
                    })
                    
                    
                })
                
            })
        }
        
        
    }
    
    func initializeBorders(){
        let width = CGFloat(2.0)
        border.borderColor = UIColor.white.cgColor
        border.frame = CGRect(x: 0, y: postsButton.frame.size.height - width, width: postsButton.frame.size.width, height: postsButton.frame.size.height)
        border.borderWidth = width
        postsButton.layer.addSublayer(border)
        postsButton.layer.masksToBounds = true
        
        
        
        
  
        eventBorder.borderColor = UIColor.white.cgColor
        eventBorder.frame = CGRect(x: 0, y: eventsButton.frame.size.height - width, width: eventsButton.frame.size.width, height: eventsButton.frame.size.height)
        eventBorder.borderWidth = width
        eventsButton.layer.addSublayer(eventBorder)
        eventsButton.layer.masksToBounds = true
   
    }
    
    func switchBorder(){
        if (self.showPosts){

            postsButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            eventsButton.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 16)
            eventBorder.removeFromSuperlayer()
            postsButton.layer.addSublayer(border)
            eventsButton.layer.masksToBounds = true
            postsButton.layer.masksToBounds = true

            
        }else{
            eventsButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            postsButton.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 16)

            border.removeFromSuperlayer()
            eventsButton.layer.addSublayer(eventBorder)
            eventsButton.layer.masksToBounds = true
            postsButton.layer.masksToBounds = true
 


        }
    }
    
    
    @IBAction func editProfileImg(_ sender: AnyObject) {
    }
    func loadUserDetail(){
        //profileInfoContainer.isHidden = false
        var charCount = self.user?.userName.characters.count
        var originalWidth = self.userNameLabel.frame.size.width
        var newWidth = 13 * charCount!
        var differenceWidth = CGFloat(newWidth) - originalWidth
        var tFrame : CGRect = self.userNameLabel.frame
        tFrame.size.width = CGFloat(newWidth)
        self.userNameLabel.frame = tFrame
        
        var x = imgView.frame.origin.x
        var newX = x + differenceWidth
        var imgFrame : CGRect = imgView.frame
        imgFrame.origin.x = newX
        self.imgView.frame = imgFrame
        userNameLabel.text = self.user?.userName
        //imgView.image = getRankMedal((self.user?.score)!)
        scoreLabel.text = "Score: " + String(describing: user!.score)
        
        if (self.user?.profileImg != "nil"){
            AWSService().getProfileImageFromUrl((self.user?.profileImg)!, completion: {(result)->Void in
                self.profileImg.image = result
                self.activityIndicator.stopAnimating()
                self.activityIndicator.removeFromSuperview()
            })
        }else{
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
        }
        if qrCodeImage == nil {
            if self.user?.userID != "" {
                let data = self.user?.userID.data(using: String.Encoding.isoLatin1, allowLossyConversion: false)
                let filter = CIFilter(name: "CIQRCodeGenerator")
                
                filter?.setValue(data, forKey: "inputMessage")
                filter?.setValue("Q", forKey: "inputCorrectionLevel")
                
                qrCodeImage = filter?.outputImage
                let scaleX = QrImageView.frame.size.width / qrCodeImage.extent.size.width
                let scaleY = QrImageView.frame.size.height / qrCodeImage.extent.size.height
                let transformedImage = qrCodeImage.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
                
                QrImageView.image = UIImage(ciImage: transformedImage)
                
            }
        }
        

        
        //distanceLabel.text = String(describing: self.user!.distance) + " mi"
        view.bringSubview(toFront: imgView)
        
    }
    
    func editSettings(_ sender: UIBarButtonItem!){
        self.performSegue(withIdentifier: "editSettings", sender: nil)
    }
    
    func connectWithUser(_ sender: UIBarButtonItem!){
        if(captureSession != nil){
            captureSession?.stopRunning()
            videoPreviewLayer?.zPosition = -1
            captureSession = nil
            connectButton.image = UIImage(named: "connect")
            self.navigationItem.title = "Profile"
             self.navigationItem.rightBarButtonItem = self.self.editButton
        }
        else{
            connectButton.image = UIImage(named: "Cancel")
            self.navigationItem.title = "Connect"
           self.navigationItem.rightBarButtonItem = nil
            let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
            
            do{
                let input: AnyObject! = try AVCaptureDeviceInput(device: captureDevice)
                captureSession = AVCaptureSession()
                captureSession?.addInput(input as! AVCaptureInput)
                
                let captureMetadataOutput = AVCaptureMetadataOutput()
                captureSession?.addOutput(captureMetadataOutput)
                
                captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
                
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                videoPreviewLayer?.frame = view.layer.bounds
                view.layer.addSublayer(videoPreviewLayer!)
                
                captureSession?.startRunning()
                
                qrCodeFrameView = UIView()
                qrCodeFrameView?.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView?.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView!)
                view.bringSubview(toFront: qrCodeFrameView!)
                
            }
            catch {
                print("Error with capture device")
                return
            }
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection : AVCaptureConnection!){
        if metadataObjects == nil || metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            print("No QR code is detected")
        }
        else{
            let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            
            if metadataObj.type == AVMetadataObjectTypeQRCode {
                let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj as AVMetadataMachineReadableCodeObject) as! AVMetadataMachineReadableCodeObject
                qrCodeFrameView?.frame = barCodeObject.bounds;
                
                if metadataObj.stringValue != nil {
                    print(metadataObj.stringValue)
                    captureSession?.stopRunning()
                    captureSession = nil
                    videoPreviewLayer?.zPosition = -1
                    qrCodeFrameView?.frame = CGRect.zero
                    connectButton.image = UIImage(named: "connect")
                    self.navigationItem.title = "Profile"
                    self.navigationItem.rightBarButtonItem = self.editButton
                    checkIfQRCodeIsUser(qrString: metadataObj.stringValue)
                }
            }
        }
    }
    
    func checkIfQRCodeIsUser(qrString: String){
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let currentDate = Date()
        
        _ = AWSService().checkIfUserExists(qrString, completion: {(result) -> Void in
            if result.userID != "" {
                _ = AWSService().loadMeetUp((self.user?.userID)! + result.userID, completion: {(meetUpResult) -> Void in
                    //if they have met up before
                    if meetUpResult.meetUpID != "" {
                        //figure out how long it's been since their last meet up
                        let lastMeetUp : Date = dateFormatter.date(from: meetUpResult.meetUpTime)!
                        
                        //get the difference in date components
                        let diffDateComponents = (Calendar.current as NSCalendar).components([NSCalendar.Unit.year, NSCalendar.Unit.month, NSCalendar.Unit.day, NSCalendar.Unit.hour, NSCalendar.Unit.minute, NSCalendar.Unit.second], from: lastMeetUp, to: currentDate, options: NSCalendar.Options.init(rawValue: 0))
                        
                        print("The difference between dates is: \(diffDateComponents.year) years, \(diffDateComponents.month) months, \(diffDateComponents.day) days, \(diffDateComponents.hour) hours, \(diffDateComponents.minute) minutes, \(diffDateComponents.second) seconds")
                        
                        //if it has been more than a day award the user points and update the check in time
                        if (diffDateComponents.year! > 0 || diffDateComponents.month! > 0 || diffDateComponents.day! > 0){
                            print("It's been a while")
                            DispatchQueue.main.async(execute: {
                                self.processSuccessfulMeetUp(currentUser: self.user!, metUser: result)
                            })
                        }
                            //if it's been less than a day, output error message
                        else{
                            DispatchQueue.main.async(execute: {
                                SCLAlertView().showError("Sorry", subTitle: "You've met up in the last 24 hours with " + result.userName)
                            })
                            
                            print("Sorry, you've met up recently.")
                        }
                        
                    }
                        // if the meetUpResult returns an empty meetUp, store new meetUp
                    else{
                        DispatchQueue.main.async(execute: {
                            self.processSuccessfulMeetUp(currentUser: self.user!, metUser: result)
                        })
                    }
                    
                })
            }
            else{
                DispatchQueue.main.async(execute: {
                    SCLAlertView().showError("Sorry", subTitle: " That code isn't a current user.")
                })
                print("Sorry, that's not a user.")
            }
            
        })
        
        
    }
    
    func processSuccessfulMeetUp(currentUser: User, metUser: User){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let currentDate = Date()
        
        currentUser.score += 10
        scoreLabel.text = "Score: " + String(currentUser.score)
        metUser.score += 10
        AWSService().save(currentUser)
        AWSService().save(metUser)
        
        print("Met user image id")
        print(metUser.profileImg)
        print("Current user image id")
        print(currentUser.profileImg)
        let currentUserNotifUUID =  UUID().uuidString
        let currentUserNotification = Notification()
        currentUserNotification?.notificationID = currentUserNotifUUID
        currentUserNotification?.userName = metUser.userName
        currentUserNotification?.ownerName = currentUser.userName
        let date = Date()
        currentUserNotification?.actionTime = String(describing: date)
        let metProfileID = metUser.profileImg
        if(metProfileID != "nil")
        {
            currentUserNotification?.imageID = metUser.profileImg
        }
        else{
            currentUserNotification?.imageID = "DefaultProfileImage"
        }
        currentUserNotification?.open = true
        currentUserNotification?.type = "meetUp"
        AWSService().save(currentUserNotification!)
        
        let metUserNotifUUID =  UUID().uuidString
        let metUserNotification = Notification()
        metUserNotification?.notificationID = metUserNotifUUID
        metUserNotification?.userName = currentUser.userName
        metUserNotification?.ownerName = metUser.userName
        metUserNotification?.actionTime = String(describing: date)
        let currentProfileID = currentUser.profileImg
        if(currentProfileID != "nil")
        {
            metUserNotification?.imageID = (self.user?.profileImg)!
        }
        else{
            metUserNotification?.imageID = "DefaultProfileImage"
        }
        metUserNotification?.open = true
        metUserNotification?.type = "meetUp"
        AWSService().save(metUserNotification!)
        
        let currentUserMeetUpID = currentUser.userID + metUser.userID
        let currentUserMeetUp = MeetUp()
        currentUserMeetUp?.meetUpID = currentUserMeetUpID
        currentUserMeetUp?.user1ID = currentUser.userID
        currentUserMeetUp?.user2ID = metUser.userID
        currentUserMeetUp?.meetUpTime = dateFormatter.string(from: currentDate)
        AWSService().save(currentUserMeetUp!)
        
        let metUserMeetUpID = metUser.userID + currentUser.userID
        let metUserMeetUp = MeetUp()
        metUserMeetUp?.meetUpID = metUserMeetUpID
        metUserMeetUp?.user1ID = metUser.userID
        metUserMeetUp?.user2ID = currentUser.userID
        metUserMeetUp?.meetUpTime = dateFormatter.string(from: currentDate)
        AWSService().save(metUserMeetUp!)
        
        print("Score: \(self.user?.score)")
        SCLAlertView().showSuccess("Congrats", subTitle: "You met up and earned 10 point!")
    }
    
    func progressBarDisplayer(_ msg:String, _ indicator:Bool ) {
        
        if indicator {
            
            
            self.activityIndicator.frame = CGRect(x:self.view.frame.midX - 50, y: self.view.frame.midY - 100, width: 100, height: 100)
            self.activityIndicator.startAnimating()
            self.view?.addSubview(self.activityIndicator)
            self.view.bringSubview(toFront: self.activityIndicator)
            
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editSettings" {
            
            
            if let destinationVC = segue.destination as? EditSettingsController{
                destinationVC.user = self.user
                destinationVC.currentImg = self.profileImg.image!
                destinationVC.profileForm = profileForm
            }
        } else if segue.identifier == "viewPost" {
            let image = Image()
            
            if let destinationVC = segue.destination as? viewPostController{
                destinationVC.imageUtil = self.imageUtil
                destinationVC.imageTapped = self.chosenImage
                print("IMAGE ID: " + (image?.imageID)!)
                destinationVC.imageObj = self.chosenImageObj
                destinationVC.imageID = (self.chosenImageObj?.imageID)!
                destinationVC.user = self.user
                
            }
            
            
            
        }else if segue.identifier == "viewEvent"{
            
            if let destinationVC = segue.destination as? ViewEventController{
                destinationVC.imageUtil = self.imageUtil
                destinationVC.user = (self.user)!
                destinationVC.selectedEvent = self.selectedEvent
                destinationVC.img = self.selectedEventImg
            }
        }
    }
    
    func getRankMedal(_ score : Int) -> UIImage{
        var medal : UIImage
        if score < 25{
            medal = UIImage(named: "Novice")!
        }else if score >= 25 && score < 50{
            medal = UIImage(named: "Regular")!
        }else if score >= 50 && score < 100{
            medal = UIImage(named: "Legend")!
        }else if score >= 100 && score < 250{
            medal = UIImage(named: "Legend")!
        }else {
            medal = UIImage(named: "Myth")!
        }
        
        return medal
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
                completion(userID!)
                
            }
            
        })
        
        
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.activityIndicator.frame = CGRect(x:self.pullView.frame.midX - 20, y: self.pullView.frame.midY - 20, width: 30, height: 50)
        self.activityIndicator.startAnimating()
        self.pullView?.addSubview(self.activityIndicator)
        self.pullView.bringSubview(toFront: self.activityIndicator)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        var offset = scrollView.contentOffset.y
        if (scrollView.contentOffset.y < 0){
            AWSService().loadUser(self.userID,completion: {(result)->Void in
                self.user = result
                DispatchQueue.main.async(execute: {
                    self.loadUserDetail()
                    if (self.showPosts){
                        self.getImages()
                    }else{
                        self.getEvents()
                    }
                    
                })
                
                
            })        }
    }
    
    //set size of each square cell to imgSize
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if (self.arrayEmpty){
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
    
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            var cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as UICollectionViewCell
            
            collectionView.backgroundColor = UIColor.clear
            cell.backgroundColor = UIColor.clear
            
            if (!self.arrayEmpty){
                
             
                
                

                    imgHeight = 200
                    imgWidth = 160
                    noColumns = 2
                
                
                let imageButton = UIButton(frame: CGRect(x: 0, y: 0, width: CGFloat(imgWidth), height: CGFloat(imgHeight)))
                imageButton.setImage(nil, for: UIControlState())
                if (self.showPosts){
                    imageButton.setImage(self.uiImageDict[self.imageArr[indexPath.row].imageID], for: UIControlState())
                }else{
                    imageButton.setImage(self.uiImageDict[self.eventsArr[indexPath.row].eventID], for: UIControlState())
                }

        
                
                //let titleViewContainer = UIView(frame: CGRect(x: 0, y: imageButton.frame.height * 0.85, width: imageButton.frame.width, height: imageButton.frame.height * 0.15))
                let titleView = UILabel(frame: CGRect(x: 0, y: imageButton.frame.height * 0.85, width: imageButton.frame.width, height: imageButton.frame.height * 0.15))
                
                if (self.showPosts){
                    titleView.text = " " + self.imageArr[(indexPath as NSIndexPath).row].placeTitle
                }else{
                    titleView.text = " " + self.eventsArr[(indexPath as NSIndexPath).row].eventTitle
                }

                titleView.textColor = UIColor.white
                titleView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.5)
                titleView.font = UIFont (name: "HelveticaNeue-Bold", size: 12)
                //titleViewContainer.backgroundColor = UIColor.darkGray.withAlphaComponent(0.4)
                //imageButton.addSubview(titleViewContainer)
                imageButton.addSubview(titleView)
                imageButton.isUserInteractionEnabled = true
                imageButton.layer.masksToBounds = true
                //
                let imagePressed :Selector = #selector(ProfileController.imagePressed(_:))
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

            }else if (self.arrayEmpty){
                DispatchQueue.main.async(execute: {
                    for v  in cell.subviews{
                        v.removeFromSuperview()
                    }
                    self.view.isUserInteractionEnabled = true
                    
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.removeFromSuperview()

                    self.emptyArrayLabel = UILabel(frame: CGRect(x: 0, y: ((self.collectionView?.frame.height)! / 2), width: self.view.frame.width, height: 50))

                    

                    if (self.showPosts){
                        self.emptyArrayLabel.text = "You have no current posts"

                    }else{
                        self.emptyArrayLabel.text = "You have no current events"
                    }
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
        if (self.showPosts){
            self.chosenImageObj = self.imageArr[(indexPath! as NSIndexPath).row]
            self.chosenImage = self.uiImageDict[self.imageArr[(indexPath?.row)!].imageID]!
            self.performSegue(withIdentifier: "viewPost", sender: nil)
        }else{
            self.selectedEvent = self.eventsArr[(indexPath?.row)!]
            self.selectedEventImg = self.uiImageDict[self.eventsArr[(indexPath?.row)!].eventID]!
            self.performSegue(withIdentifier: "viewEvent", sender: 1)
        }

        
    }
    

    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (self.arrayEmpty){
            return 1
        }else if (self.showPosts){
            return self.imageArr.count
        }else if (self.showEvents){
            return self.eventsArr.count
        }else{
            return 1
        }
    }
    
    func createUIImageDict() -> [String: UIImage]{
        
        var dict = [String: UIImage]()
        if (self.showPosts){
            for i in 0...self.imageArr.count-1{
                
                dict[self.imageArr[i].imageID] = self.uiImageArr[i]
                
            }
        }else{
            for i in 0...self.eventsArr.count-1{
                
                dict[self.eventsArr[i].eventID] = self.uiImageArr[i]
                
            }
        }

        return dict
    }
    
    func progressBarWithOverlay(_ msg:String, _ indicator:Bool ) {
        
        if indicator {

            self.activityIndicator.frame = CGRect(x:self.view.frame.midX - 50, y: self.view.frame.midY - 50, width: 100, height: 100)
            self.activityIndicator.startAnimating()
            
            
        }
    }
    
    func getImages(){
        progressBarDisplayer("Loading", true)
        self.imageArr = []
        self.eventsArr = []
        getImagesForUser(completion: {(result)->Void in

            self.uiImageArr = []
            self.uiImageDict = [:]
            

            if (self.imageArr.count == 0){
                self.arrayEmpty = true
                self.collectionView!.reloadData()
                
            }else{
                self.arrayEmpty = false
                
                
                for img in self.imageArr{
                    AWSService().getImageFromUrl(String(img.imageID), bucket: "liveniteimages", completion: {(result)->Void in
                        self.uiImageArr.append(result)
                        if self.uiImageArr.count == self.imageArr.count{
                            
                            DispatchQueue.main.async(execute: {
                                self.uiImageDict = self.createUIImageDict()
                                
                                self.view.isUserInteractionEnabled = true
                                
                                self.collectionView!.reloadData()
                            })
                            
                        }
                    })
                }
            }
        })

    }
    
    func getEvents(){
        progressBarDisplayer("Loading", true)
        self.imageArr = []
        self.eventsArr = []
        getEventsForUser(completion: {(result)->Void in

            self.uiImageArr = []
            self.uiImageDict = [:]
            
            
            if (self.eventsArr.count == 0){
                self.arrayEmpty = true
                self.collectionView!.reloadData()
                
            }else{
                self.arrayEmpty = false
                
                
                for e in self.eventsArr{
                    AWSService().getImageFromUrl(String(e.url), bucket: "liveniteimages", completion: {(result)->Void in
                        self.uiImageArr.append(result)
                        if self.uiImageArr.count == self.eventsArr.count{
                            
                            DispatchQueue.main.async(execute: {
                                self.uiImageDict = self.createUIImageDict()
                                
                                self.view.isUserInteractionEnabled = true
                                
                                self.collectionView!.reloadData()
                            })
                            
                        }
                    })
                }
            }
        })
    }
    
    func getImagesForUser(completion:@escaping ([Image])->Void)->[Image]{
        
     
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBScanExpression()


        queryExpression.filterExpression = "userID = :userID"

        queryExpression.expressionAttributeValues = [":userID": self.user?.userID]
        
        
        
        dynamoDBObjectMapper.scan(Image.self, expression: queryExpression).continue({(task: AWSTask) -> AnyObject in
            if (task.error != nil) {
                print("The request failed. Error: [\(task.error)]")
            }
            if (task.exception != nil) {
                print("The request failed. Exception: [\(task.exception)]")
            }
            if (task.result != nil) {
                let output : AWSDynamoDBPaginatedOutput = task.result!
                for img  in output.items {
                    let img : Image = img as! Image
                    self.imageArr.append(img)
                }
                completion(self.imageArr)
                return self.imageArr as AnyObject
                
            }
            return self.imageArr as AnyObject
        })
        
        
        return imageArr
        
    }
    



    
    override func viewWillAppear(_ animated: Bool){
        if (profileForm.madeEdits){
            profileForm.madeEdits = false
            userNameLabel.text = profileForm.userName
            
        }
        if (profileForm.didSaveNewImage){
            profileImg.image = profileForm.selectedImage
        }
        
    }
    
    @IBAction func eventsToggle(_ sender: Any) {
        self.showPosts = false
        self.showEvents = true
        switchBorder()
        getEvents()
    }
    
    @IBAction func postsToggle(_ sender: Any) {
        self.showPosts = true
        self.showEvents = false
        switchBorder()
        getImages()
        
    }
    
    override func viewDidLayoutSubviews() {

        scrollView.contentSize = CGSize(width: CGFloat(contentView.frame.size.width), height: CGFloat(contentView.frame.size.height))
    }
    
    func getEventsForUser(completion:@escaping ([Event])->Void)->[Event]{
        
        
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBScanExpression()
        
        
        queryExpression.filterExpression = "ownerID = :userID"
        
        queryExpression.expressionAttributeValues = [":userID": self.user?.userID]
        
        
        
        dynamoDBObjectMapper.scan(Event.self, expression: queryExpression).continue({(task: AWSTask) -> AnyObject in
            if (task.error != nil) {
                print("The request failed. Error: [\(task.error)]")
            }
            if (task.exception != nil) {
                print("The request failed. Exception: [\(task.exception)]")
            }
            if (task.result != nil) {
                let output : AWSDynamoDBPaginatedOutput = task.result!
                for e  in output.items {
                    let e : Event = e as! Event
                    self.eventsArr.append(e)
                }
                completion(self.eventsArr)
                return self.eventsArr as AnyObject
                
            }
            return self.eventsArr as AnyObject
        })
        
        
        return eventsArr
        
    }
}
