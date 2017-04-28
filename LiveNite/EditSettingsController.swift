//
//  EditSettingsController.swift
//  LiveNite
//
//  Created by Kevin on 3/1/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//

import AWSDynamoDB

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
        distanceLabel.text = String(describing: (self.user?.distance)!)
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
        var changeUserName = false
        var newDistance = Int(distanceLabel.text!)
        if (self.selected){
            let tempImage = self.selectedImage
            let dataImage:Data = UIImageJPEGRepresentation(tempImage, 0.0)!
            AWSService().saveProfileImageToBucket(dataImage, id: (self.user?.userID)!, completion: {(result)->Void in
                DispatchQueue.main.async(execute: {
                    var imageURL = result
                    self.user?.profileImg = imageURL
                    if (self.user?.userName != newUserName!){
                        var oldUserName = self.user?.userName
                        self.user?.userName = newUserName!

                        self.updateUserNameForTables(oldUserName!)
                    }
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
            if (self.user?.userName != newUserName!){
                var oldUserName = self.user?.userName
                self.user?.userName = newUserName!
               updateUserNameForTables(oldUserName!)
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

    
    func updateUserNameForTables(_ oldUserName : String){
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        var scanExpression = AWSDynamoDBScanExpression()
        scanExpression.filterExpression = "ownerName = :val1"
        scanExpression.expressionAttributeValues = [":val1": oldUserName]

        
        dynamoDBObjectMapper.scan(Image.self, expression: scanExpression).continue({(task: AWSTask) -> String in
            if (task.error != nil) {
                print("The request failed. Error: [\(task.error)]")
            }
            if (task.exception != nil) {
                print("The request failed. Exception: [\(task.exception)]")
            }
            if (task.result != nil) {
                let output : AWSDynamoDBPaginatedOutput = task.result!
                for image  in output.items {
                    let image : Image = image as! Image
                    image.ownerName = (self.user?.userName)!
                    AWSService().save(image)
                        
                    }
                return "success"
            }

            
            return "success"

    })
        

        scanExpression = AWSDynamoDBScanExpression()
        scanExpression.filterExpression = "ownerName = :val1 or userName = :val2"
        scanExpression.expressionAttributeValues = [":val1": oldUserName, ":val2": oldUserName]
        
        
        dynamoDBObjectMapper.scan(Notification.self, expression: scanExpression).continue({(task: AWSTask) -> String in
            if (task.error != nil) {
                print("The request failed. Error: [\(task.error)]")
            }
            if (task.exception != nil) {
                print("The request failed. Exception: [\(task.exception)]")
            }
            if (task.result != nil) {
                let output : AWSDynamoDBPaginatedOutput = task.result!
                for notif  in output.items {
                    let notif : Notification = notif as! Notification
                    if (notif.ownerName == oldUserName){
                        notif.ownerName = (self.user?.userName)!
                    }
                    if (notif.userName == oldUserName){
                        notif.userName = (self.user?.userName)!
                    }
                    AWSService().save(notif)
                    
                }
                return "success"
            }
            
            return "success"
            
            
        })

        scanExpression = AWSDynamoDBScanExpression()
        scanExpression.filterExpression = "ownerName = :val1"
        scanExpression.expressionAttributeValues = [":val1": oldUserName]

        
        dynamoDBObjectMapper.scan(Event.self, expression: scanExpression).continue({(task: AWSTask) -> String in
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
                    e.ownerName = (self.user?.userName)!
                    AWSService().save(e)
                        
                    }
                return "success"
            }
            return "success"

            
            

    })

        scanExpression = AWSDynamoDBScanExpression()
        scanExpression.filterExpression = "ownerName = :val1"
        scanExpression.expressionAttributeValues = [":val1": oldUserName]

        
        dynamoDBObjectMapper.scan(Event.self, expression: scanExpression).continue({(task: AWSTask) -> String in
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
                    e.ownerName = (self.user?.userName)!
                    AWSService().save(e)
                        
                    }
                return "success"
            }
            return "success"


            
            

    })

        scanExpression = AWSDynamoDBScanExpression()
        scanExpression.filterExpression = "ownerName = :val1"
        scanExpression.expressionAttributeValues = [":val1": oldUserName]

        
        dynamoDBObjectMapper.scan(Vote.self, expression: scanExpression).continue({(task: AWSTask) -> String in
            if (task.error != nil) {
                print("The request failed. Error: [\(task.error)]")
            }
            if (task.exception != nil) {
                print("The request failed. Exception: [\(task.exception)]")
            }
            if (task.result != nil) {
                let output : AWSDynamoDBPaginatedOutput = task.result!
                for v  in output.items {
                    let v : Vote = v as! Vote
                    v.ownerName = (self.user?.userName)!
                    AWSService().save(v)
                        
                    }
                return "success"
            }
            return "success"


            
            

    })

        scanExpression = AWSDynamoDBScanExpression()
        scanExpression.filterExpression = "ownerName = :val1"
        scanExpression.expressionAttributeValues = [":val1": oldUserName]

        
        dynamoDBObjectMapper.scan(Comment.self, expression: scanExpression).continue({(task: AWSTask) -> String in
            if (task.error != nil) {
                print("The request failed. Error: [\(task.error)]")
            }
            if (task.exception != nil) {
                print("The request failed. Exception: [\(task.exception)]")
            }
            if (task.result != nil) {
                let output : AWSDynamoDBPaginatedOutput = task.result!
                for c  in output.items {
                    let c : Comment = c as! Comment
                    c.ownerName = (self.user?.userName)!
                    AWSService().save(c)
                        
                    }
                return "success"
            }
            return "success"


            
            

    })

    }


    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)


     if (self.selected){
            profileImgView.image = self.selectedImage
        }
    }
    

    
}
