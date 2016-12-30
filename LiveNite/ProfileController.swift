//
//  ProfileController.swift
//  LiveNite
//
//  Created by Kevin on 3/1/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//



class ProfileController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate{
    
    
    
   
    
    
    var locations = 0
    var locationUpdated = false
    var toggleState = 0
    var hotToggle = 0
    var profileMenu = UIView()
    var accessToken = ""
    var userID = ""
    var user = User()
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var imgView: UIImageView!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.view.isHidden = false
        
    }
    @IBOutlet weak var sliderValue: UISlider!
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let currentVal = round(sender.value / 2) * 2
        distanceLabel.text = "Distance: " + String(currentVal) + " miles"
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.topItem?.title = "Profile"
        
        navigationController?.navigationBar.tintColor = UIColor.white
        
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
    func loadUserDetail(){
        userNameLabel.text = self.user?.userName
        imgView.image = getRankMedal((self.user?.score)!)
        scoreLabel.text = "Score: " + String(describing: user!.score)
        sliderValue.value = Float((self.user?.distance)!)
        distanceLabel.text = "Distance: " + String(describing: self.user!.distance) + " miles"
        view.bringSubview(toFront: imgView)
        
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

}
