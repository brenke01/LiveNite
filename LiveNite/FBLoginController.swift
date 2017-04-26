//
//  LoginController.swift
//  LiveNite
//
//  Created by Kevin on 1/12/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//

import Foundation
import UIKit
import Foundation
import UIKit
import MediaPlayer
import MobileCoreServices
import AVFoundation
import CoreData
import CoreLocation
import GoogleMaps
import SCLAlertView
import AWSDynamoDB



class FBLoginController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate, FBSDKLoginButtonDelegate, UITextFieldDelegate{
    var locations = 0
    var blockedCharacters = CharacterSet.alphanumerics.inverted
    
    @IBOutlet var submitButton: UIButton!
    @IBOutlet var inputUserName: UITextField!
    var userID : String = ""
    var loadMask = UIView()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(loadMask)
        loadMask.isHidden = true
        inputUserName.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        submitButton.isHidden = true
        inputUserName.isHidden = true
        submitButton.isEnabled = false
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "Background_Gradient")!)
        let loginView : FBSDKLoginButton = FBSDKLoginButton()
        self.view.addSubview(loginView)
        loginView.center = self.view.center
        loginView.readPermissions = ["public_profile", "email"]
        loginView.delegate = self
        loadMask = UIView(frame: CGRect(x: 0, y:0, width: self.view.frame.width, height: self.view.frame.height))
        loadMask.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        FBSDKProfile.enableUpdates(onAccessTokenChange: true)
        
    }
    
    @IBAction func submitAction(_ sender: AnyObject) {
        print("submit")
        var username = inputUserName.text
        var trimmedUsername = username?.trimmingCharacters(in: CharacterSet.whitespaces)
        username = trimmedUsername!
        loadMask.isHidden = false
        self.view.isUserInteractionEnabled = false
        self.findUsername(username: trimmedUsername!, completion: {(result)->Void in
              DispatchQueue.main.async(execute: {
                    if (result.count >= 1){
                       
                        SCLAlertView().showError("Sorry", subTitle: "That username is taken. Please choose another username")
                            self.loadMask.isHidden = true
                            self.view.isUserInteractionEnabled = true
                       

                    }else{
                        var user : User = AWSService().loadUser(self.userID, newUserName: self.inputUserName.text!)
                        self.dismiss(animated: true, completion: nil)
                        self.loadMask.isHidden = true
                        self.view.isUserInteractionEnabled = true
                    }
                 })
        })

        
        
        
    }
    
    // Facebook Delegate Methods
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        
        
        if ((error) != nil)
        {
            // Process error
        }
        else if result.isCancelled {
            // Handle cancellations
        }
        else {
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
            if result.grantedPermissions.contains("email")
            {
                // Do work
                
                returnUserData()
            }
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        
    }
    
    func saveUserToCoreData(_ fbResult : AnyObject){
        var newUser : Bool = true
        var userObj = User()
        AWSService().loadUser(fbResult.value(forKey: "id") as! String,completion: {(result)->Void in
            userObj = result
            
            if (userObj?.userID != ""){
                newUser = false
            }
            //The result from the Facebook request is an object that works like a Dictionary
            //First we grab all of the fields

            //This is our predicate for the table that will ask for a record that has an id of userID
            
            
            
            if (newUser){
                self.userID = fbResult.value(forKey: "id") as! String
                let firstName = fbResult.value(forKey: "first_name")
                let email = fbResult.value(forKey: "email") as! String
                let gender = fbResult.value(forKey: "gender")
                let ageRange = (fbResult.value(forKey: "age_range") as AnyObject).value(forKey: "min")
                let newUserObj : User = User()
                newUserObj.userID = self.userID
                newUserObj.age = ageRange as! Int
                newUserObj.gender = String(describing: gender!)
                newUserObj.accessToken = String(describing: (FBSDKAccessToken.current()!))
                newUserObj.score = 0
                newUserObj.email = email
                newUserObj.userName = "temp"
                newUserObj.profileImg = "nil"
                AWSService().save(newUserObj)
                self.submitButton.isHidden = false
                self.submitButton.slideInFromLeft()
                self.view.bringSubview(toFront: self.submitButton)
                self.inputUserName.isHidden = false
                self.inputUserName.slideInFromLeft()
                self.submitButton.alpha = 0.7
                self.submitButton.isEnabled = false
                self.submitButton.layer.cornerRadius = 5
                
            }else{
                DispatchQueue.main.async(execute: {
                print(FBSDKAccessToken.current())
                userObj?.accessToken = String(describing: FBSDKAccessToken.current()!)
                AWSService().save(userObj!)
                    self.dismiss(animated: true, completion: nil)

                })
            }
        })

        
    }
    func returnUserData()
    {
        //The graphRequest is Facebooks Graph API. If you want to grab more parameters, look up the fields
        // on their documentation and add them
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, first_name, gender, age_range, email"])
        graphRequest.start(completionHandler: { (connection, result, error) -> Void in
            
            if ((error) != nil)
            {
                // Process error
                print("Error: \(error)")

            }
            else
            {   //Save the user to the Users table
               self.saveUserToCoreData(result as AnyObject)

            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (inputUserName.text != ""){
            submitButton.alpha = 1.0
            submitButton.isEnabled = true
        }else{
            submitButton.alpha = 0.7
            submitButton.isEnabled = false
        }
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField!) -> Bool {
        inputUserName.resignFirstResponder()
        if (inputUserName.text != ""){
            submitButton.alpha = 1.0
            submitButton.isEnabled = true
        }else{
            submitButton.alpha = 0.7
            submitButton.isEnabled = false

        }
        return true
    }
    
    func findUsername(username: String, completion:@escaping ([User])->Void)->[User]{
        
        var userArray = [User]()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.filterExpression = "userName = :val"
        scanExpression.expressionAttributeValues = [":val": username]
        
        
        
        
        dynamoDBObjectMapper.scan(User.self, expression: scanExpression).continue({(task: AWSTask) -> AnyObject in
            if (task.error != nil) {
                print("The request failed. Error: [\(task.error)]")
            }
            if (task.exception != nil) {
                print("The request failed. Exception: [\(task.exception)]")
            }
            if (task.result != nil) {
                let output : AWSDynamoDBPaginatedOutput = task.result!
                for user  in output.items {
                    let user : User = user as! User
                    userArray.append(user)
                }
                completion(userArray)
                return userArray as AnyObject
                
            }
            return userArray as AnyObject
        })
        
        
        return userArray
        
    }
    
    func textField(_ field: UITextField, shouldChangeCharactersIn range: NSRange, replacementString characters: String) -> Bool{
        guard let text = field.text else { return true }
        let newLength = text.characters.count + characters.characters.count - range.length
        var length = newLength <= 12 // Bool
        var validCharacters = ((characters as NSString).rangeOfCharacter(from: self.blockedCharacters).location == NSNotFound)
        return length && validCharacters
    }
    
    
    
}

extension UIView {
    // Name this function in a way that makes sense to you...
    // slideFromLeft, slideRight, slideLeftToRight, etc. are great alternative names
    func slideInFromLeft(duration: TimeInterval = 0.5, completionDelegate: AnyObject? = nil) {
        // Create a CATransition animation
        let slideInFromLeftTransition = CATransition()
        
        // Set its callback delegate to the completionDelegate that was provided (if any)
        if let delegate: CAAnimationDelegate = completionDelegate as! CAAnimationDelegate? {
            slideInFromLeftTransition.delegate = delegate
        }
        
        // Customize the animation's properties
        slideInFromLeftTransition.type = kCATransitionPush
        slideInFromLeftTransition.subtype = kCATransitionFromLeft
        slideInFromLeftTransition.duration = duration
        slideInFromLeftTransition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        slideInFromLeftTransition.fillMode = kCAFillModeRemoved
        
        // Add the animation to the View's layer
        self.layer.add(slideInFromLeftTransition, forKey: "slideInFromLeftTransition")
    }
}
