//
//  ProfileController.swift
//  LiveNite
//
//  Created by Kevin on 3/1/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//



class ProfileController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate{
    
    
    
   
    
    
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
        profilebkg.backgroundColor? = UIColor.white.withAlphaComponent(0.2)
        navigationController?.navigationBar.topItem?.title = "Profile"
        profileImg.layer.borderWidth = 2
        profileImg.layer.borderColor = UIColor.white.cgColor
        profileImg.layer.masksToBounds = true
        //profileImg.backgroundColor = UIColor(red: 58/255, green:67/255, blue:96/255, alpha:1)
        navigationController?.navigationBar.tintColor = UIColor.white
        var editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(self.editSettings))
        self.navigationItem.rightBarButtonItem = editButton

        if (self.user?.userID == ""){
            retrieveUserID({(result)->Void in
                self.userID = result
                AWSService().loadUser(self.userID,completion: {(result)->Void in
                    self.user = result
                    DispatchQueue.main.async(execute: {
                         self.loadUserDetail()
                        
                    })
                   
                    
                })
                
            })
        }
        

    }

    
    @IBAction func editProfileImg(_ sender: AnyObject) {
    }
    func loadUserDetail(){
        userNameLabel.text = self.user?.userName
        imgView.image = getRankMedal((self.user?.score)!)
        scoreLabel.text = "Score: " + String(describing: user!.score)

        if (self.user?.profileImg != "nil"){
            AWSService().getProfileImageFromUrl((self.user?.profileImg)!, completion: {(result)->Void in
                self.profileImg.image = result
            })
        }
        distanceLabel.text = String(describing: self.user!.distance) + " mi"
        view.bringSubview(toFront: imgView)
        
    }
    
    func editSettings(_ sender: UIBarButtonItem!){
        self.performSegue(withIdentifier: "editSettings", sender: nil)
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
        distanceLabel.text = profileForm.distance + " mi"
        userNameLabel.text = profileForm.userName
        if (profileForm.didSaveNewImage){
            profileImg.image = profileForm.selectedImage
        }
        
    }

}
