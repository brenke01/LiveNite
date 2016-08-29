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

var userID : String = ""

class FBLoginController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate, FBSDKLoginButtonDelegate{
    var locations = 0
    
    
    @IBOutlet var submitButton: UIButton!
    @IBOutlet var inputUserName: UITextField!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        submitButton.hidden = true
        inputUserName.hidden = true
        submitButton.enabled = false
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "Background_Gradient")!)
        let loginView : FBSDKLoginButton = FBSDKLoginButton()
        self.view.addSubview(loginView)
        loginView.center = self.view.center
        loginView.readPermissions = ["public_profile", "email"]
        loginView.delegate = self
        FBSDKProfile.enableUpdatesOnAccessTokenChange(true)
        
    }
    
    @IBAction func submitAction(sender: AnyObject) {
        print("submit")
        print(userID)
        var user : User = AWSService().loadUser(userID, newUserName: inputUserName.text!)
        

        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Facebook Delegate Methods
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        
        
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
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        
    }
    
    func saveUserToCoreData(result : AnyObject){
        var newUser : Bool = true
        var userObj = User()
        AWSService().loadUser(userID,completion: {(result)->Void in
            userObj = result
        })

        if (userObj.userID != ""){
            newUser = false
        }
        //The result from the Facebook request is an object that works like a Dictionary 
        //First we grab all of the fields
        userID = result.valueForKey("id") as! String
        let firstName = result.valueForKey("first_name") as! AnyObject?
        let email = result.valueForKey("email") as! String
        let gender = result.valueForKey("gender") as! AnyObject?
        let ageRange = result.valueForKey("age_range")?.valueForKey("min") as! AnyObject?
        //This is our predicate for the table that will ask for a record that has an id of userID
        

        
        if (newUser){
            var newUserObj : User = User()
            newUserObj.userID = userID
            newUserObj.age = ageRange as! Int
            newUserObj.gender = String(gender)
            newUserObj.accessToken = String(FBSDKAccessToken.currentAccessToken())
            newUserObj.score = 0
            newUserObj.email = email
            newUserObj.userName = "temp"
            AWSService().save(newUserObj)
            submitButton.hidden = false
            inputUserName.hidden = false
            submitButton.enabled = true
            submitButton.backgroundColor = UIColor.grayColor()
            submitButton.layer.cornerRadius = 5

        }else{
            userObj.accessToken = FBSDKAccessToken.currentAccessToken() as! String
            AWSService().save(userObj)
        }
        
    }
    func returnUserData()
    {
        //The graphRequest is Facebooks Graph API. If you want to grab more parameters, look up the fields
        // on their documentation and add them
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, first_name, gender, age_range, email"])
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if ((error) != nil)
            {
                // Process error
                print("Error: \(error)")

            }
            else
            {   //Save the user to the Users table
                self.saveUserToCoreData(result)
                if (self.submitButton.enabled == false) {
                    self.dismissViewControllerAnimated(true, completion: nil)
                }

            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        inputUserName.resignFirstResponder()
        return true
    }
    
}
