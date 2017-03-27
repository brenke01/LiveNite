//
//  ProfileController.swift
//  LiveNite
//
//  Created by Kevin on 3/1/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//
import AVFoundation
import SCLAlertView

class ProfileController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate, AVCaptureMetadataOutputObjectsDelegate{
    
    
    @IBOutlet var QrImageView: UIImageView!
    var qrCodeImage : CIImage!
    var captureSession : AVCaptureSession?
    var videoPreviewLayer : AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
   
    @IBOutlet weak var profileInfoContainer: UIView!
    
    
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
    @IBOutlet weak var sliderValue: UISlider!
    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profileInfoContainer.isHidden = true
        profileInfoContainer.backgroundColor = UIColor.clear
        profilebkg.backgroundColor? = UIColor.white.withAlphaComponent(0.2)
        navigationController?.navigationBar.topItem?.title = "Profile"
        profileImg.layer.borderWidth = 2
        profileImg.layer.borderColor = UIColor.white.cgColor
        profileImg.layer.masksToBounds = true
        //profileImg.backgroundColor = UIColor(red: 58/255, green:67/255, blue:96/255, alpha:1)
        navigationController?.navigationBar.tintColor = UIColor.white
        var editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(self.editSettings))
        self.navigationItem.rightBarButtonItem = editButton

        var connectButton = UIBarButtonItem(title: "Connect", style: .plain, target: self, action: #selector(self.connectWithUser))
        self.navigationItem.leftBarButtonItem = connectButton
        
        if (self.user?.userID == ""){
            retrieveUserID({(result)->Void in
                self.userID = result
                AWSService().loadUser(self.userID,completion: {(result)->Void in
                    self.user = result
                    DispatchQueue.main.async(execute: {
                        self.progressBarDisplayer("Loading", true)
                         self.loadUserDetail()
                        
                    })
                   
                    
                })
                
            })
        }
        

    }

    
    @IBAction func editProfileImg(_ sender: AnyObject) {
    }
    func loadUserDetail(){
        profileInfoContainer.isHidden = false
        userNameLabel.text = self.user?.userName
        imgView.image = getRankMedal((self.user?.score)!)
        scoreLabel.text = String(describing: user!.score)

        if (self.user?.profileImg != "nil"){
            AWSService().getProfileImageFromUrl((self.user?.profileImg)!, completion: {(result)->Void in
                self.profileImg.image = result
                activityIndicator.removeFromSuperview()
            })
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
        
        distanceLabel.text = String(describing: self.user!.distance) + " mi"
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
        }
        else{
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
                    checkIfQRCodeIsUser(qrString: metadataObj.stringValue)
                }
            }
        }
    }
    
    func checkIfQRCodeIsUser(qrString: String){
        
        _ = AWSService().checkIfUserExists(qrString, completion: {(result) -> Void in
            if result.userID != "" {
                self.user?.score += 1
                result.score += 1
                AWSService().save(self.user!)
                AWSService().save(result)
                
                print("Met user image id")
                print(result.profileImg)
                print("Current user image id")
                print((self.user?.profileImg)!)
                let currentUserNotifUUID =  UUID().uuidString
                let currentUserNotification = Notification()
                currentUserNotification?.notificationID = currentUserNotifUUID
                currentUserNotification?.userName = result.userName
                currentUserNotification?.ownerName = (self.user?.userName)!
                let date = Date()
                currentUserNotification?.actionTime = String(describing: date)
                let metProfileID = result.profileImg
                if(metProfileID != "nil")
                {
                    currentUserNotification?.imageID = result.profileImg
                }
                else{
                    currentUserNotification?.imageID = "DefaultProfileImage"
                }
                currentUserNotification?.open = false
                currentUserNotification?.type = "meetUp"
                AWSService().save(currentUserNotification!)
                
                let metUserNotifUUID =  UUID().uuidString
                let metUserNotification = Notification()
                metUserNotification?.notificationID = metUserNotifUUID
                metUserNotification?.userName = (self.user?.userName)!
                metUserNotification?.ownerName = result.userName
                metUserNotification?.actionTime = String(describing: date)
                let currentProfileID = self.user?.profileImg
                if(currentProfileID != "nil")
                {
                    metUserNotification?.imageID = (self.user?.profileImg)!
                }
                else{
                    metUserNotification?.imageID = "DefaultProfileImage"
                }
                metUserNotification?.open = false
                metUserNotification?.type = "meetUp"
                AWSService().save(metUserNotification!)
                
                print("Score: \(self.user?.score)")
                SCLAlertView().showSuccess("Congrats", subTitle: "You met up and earned 1 point!")
            }
            else{
                SCLAlertView().showError("Sorry", subTitle: qrString + " isn't a current user.")
            }
            
        })
        
        
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
            }}}
    
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
    
    override func viewWillAppear(_ animated: Bool){
        if (profileForm.madeEdits){
            profileForm.madeEdits = false
            distanceLabel.text = profileForm.distance + " mi"
            userNameLabel.text = profileForm.userName

        }
        if (profileForm.didSaveNewImage){
            profileImg.image = profileForm.selectedImage
        }
        
    }

}
