//
//  EditSettingsController.swift
//  LiveNite
//
//  Created by Kevin on 3/1/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//



class EditSettingsController: UIViewController,UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate, UIImagePickerControllerDelegate{


    var user = User()
    var profileForm = ProfileSettingsForm()
    let imagePicker = UIImagePickerController()
    var selectedImage = UIImage()
    var selected = false
    var currentImg = UIImage()
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var userNameEdit: UITextField!
    @IBOutlet weak var distanceContainer: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet weak var userNameView: UIView!
    @IBOutlet weak var sliderValue: UISlider!
    
    @IBOutlet weak var profileImgView: UIImageView!
    @IBOutlet weak var distanceView: UIView!
    @IBOutlet weak var userNameContainer: UIView!
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let currentVal = round(sender.value / 2) * 2
        distanceLabel.text = String(Int(currentVal))
    }
    
    
    @IBAction func editProfileImg(_ sender: AnyObject) {
        
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        imagePicker.modalPresentationStyle = .popover
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:[String : Any]) {
        let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage
            
        //profileImgView.contentMode = .scaleAspectFit
        self.selectedImage = pickedImage!
         self.selected = true
         dismiss(animated: true, completion: nil)
        
       
       
        
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        if (self.user?.profileImg != "nil"){
            profileImgView.image = currentImg
        }
        self.profileForm.didSaveNewImage = false
        profileImgView.layer.borderWidth = 2
        profileImgView.layer.borderColor = UIColor.white.cgColor
        profileImgView.layer.masksToBounds = true
        //profileImgView.backgroundColor = UIColor(red: 58/255, green:67/255, blue:96/255, alpha:1)
        imagePicker.delegate = self
        navigationController?.navigationBar.topItem?.title = "Profile"
        loadUserDetail()
        navigationController?.navigationBar.tintColor = UIColor.white
        userNameEdit.text = self.user?.userName
            sliderValue.value = Float((self.user?.distance)!)
        distanceLabel.text = (describing: String(self.user!.distance)) + " mi"
        userNameView.layer.borderWidth = 2
        distanceView.layer.borderWidth = 2
        userNameView.layer.borderColor = UIColor.white.cgColor
        distanceView.layer.borderColor = UIColor.white.cgColor
        distanceView.layer.masksToBounds = true
        userNameView.layer.masksToBounds = true
        
        
    }
    
    func loadUserDetail(){
        
        sliderValue.value = Float((self.user?.distance)!)
        distanceLabel.text = "Distance: " + String(describing: self.user!.distance) + " mi"
      
        
    }
    
    @IBAction func saveSettings(_ sender: AnyObject) {
        var newUserName = userNameEdit.text
        var newDistance = Int(distanceLabel.text!)
        if (self.selected){
            let tempImage = self.selectedImage
            let dataImage:Data = UIImageJPEGRepresentation(tempImage, 0.0)!
            AWSService().saveProfileImageToBucket(dataImage, id: (self.user?.userID)!, completion: {(result)->Void in
                DispatchQueue.main.async(execute: {
                    var imageURL = result
                    self.user?.profileImg = imageURL
                    self.user?.userName = newUserName!
                    if (newDistance != nil){
                        self.user?.distance = newDistance!
                        self.profileForm.distance = String(newDistance!)
                    }else{
                        self.profileForm.distance = String(describing: (self.user?.distance)!)
                    }
                    AWSService().save(self.user!)
                    self.profileForm.selectedImage = self.selectedImage
                    self.profileForm.userName = newUserName!
                    self.profileForm.didSaveNewImage = true
                    self.dismiss(animated: true, completion: nil)
                    })
                })
        }else{
            if (newUserName != nil){
                profileForm.madeEdits = true
            }
            self.user?.userName = newUserName!
            if (newDistance != nil){
                profileForm.madeEdits = true
                self.user?.distance = newDistance!
                self.profileForm.distance = String(newDistance!)
                
            }else{
                self.profileForm.distance = String(describing: (self.user?.distance)!)
            }
            AWSService().save(self.user!)
            self.profileForm.selectedImage = currentImg
            
            self.profileForm.userName = newUserName!
            self.dismiss(animated: true, completion: nil)
        }

        
    }

    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)


     if (self.selected){
            profileImgView.image = self.selectedImage
        }
    }
    

    
}
