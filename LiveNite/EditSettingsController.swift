//
//  EditSettingsController.swift
//  LiveNite
//
//  Created by Kevin on 3/1/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//



class EditSettingsController: UIViewController,UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate{


    var user = User()
    
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var userNameEdit: UITextField!
    @IBOutlet weak var distanceContainer: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet weak var userNameView: UIView!
    @IBOutlet weak var sliderValue: UISlider!
    
    @IBOutlet weak var distanceView: UIView!
    @IBOutlet weak var userNameContainer: UIView!
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let currentVal = round(sender.value / 2) * 2
        distanceLabel.text = String(Int(currentVal))
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.topItem?.title = "Profile"
        loadUserDetail()
        navigationController?.navigationBar.tintColor = UIColor.white
        userNameEdit.text = self.user?.userName
            sliderValue.value = Float((self.user?.distance)!)
        distanceLabel.text = (describing: String(self.user!.distance))
        userNameView.layer.borderWidth = 1
        distanceView.layer.borderWidth = 1
        userNameView.layer.borderColor = UIColor.white.cgColor
        distanceView.layer.borderColor = UIColor.white.cgColor
        distanceView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        userNameView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        distanceView.layer.masksToBounds = true
        userNameView.layer.masksToBounds = true
        
        
    }
    
    func loadUserDetail(){
        
        sliderValue.value = Float((self.user?.distance)!)
        distanceLabel.text = "Distance: " + String(describing: self.user!.distance) + " miles"
      
        
    }
    
    @IBAction func saveSettings(_ sender: AnyObject) {
        var newUserName = userNameEdit.text
        var newDistance = Int(distanceLabel.text!)
        self.user?.userName = newUserName!
        self.user?.distance = newDistance!
        AWSService().save(self.user!)
        self.dismiss(animated: false, completion: nil)
        
    }

    

    

    
}
