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



class FBLoginController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate, FBSDKLoginButtonDelegate{
    var locations = 0
    
    
    @IBOutlet var submitButton: UIButton!
    @IBOutlet var inputUserName: UITextField!
    var userID : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        
        FBSDKProfile.enableUpdates(onAccessTokenChange: true)
        
    }
    
    @IBAction func submitAction(_ sender: AnyObject) {
        print("submit")
        print(userID)
        var user : User = AWSService().loadUser(userID, newUserName: inputUserName.text!)
        

        self.dismiss(animated: true, completion: nil)
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
    
    func saveUserToCoreData(_ result : AnyObject){
        var newUser : Bool = true
        var userObj = User()
        AWSService().loadUser("10153244164880906",completion: {(result)->Void in
            userObj = result
            
            if (userObj?.userID != ""){
                newUser = false
            }
            //The result from the Facebook request is an object that works like a Dictionary
            //First we grab all of the fields

            //This is our predicate for the table that will ask for a record that has an id of userID
            
            
            
            if (newUser){
                self.userID = result.value(forKey: "id") as! String
                let firstName = result.value(forKey: "first_name")
                let email = result.value(forKey: "email") as! String
                let gender = result.value(forKey: "gender")
                let ageRange = (result.value(forKey: "age_range") as AnyObject).value(forKey: "min")
                let newUserObj : User = User()
                newUserObj.userID = self.userID
                newUserObj.age = ageRange as! Int
                newUserObj.gender = String(describing: gender!)
                newUserObj.accessToken = String(describing: FBSDKAccessToken.current())
                newUserObj.score = 0
                newUserObj.email = email
                newUserObj.userName = "temp"
                AWSService().save(newUserObj)
                self.submitButton.isHidden = false
                self.inputUserName.isHidden = false
                self.submitButton.isEnabled = true
                self.submitButton.backgroundColor = UIColor.gray
                self.submitButton.layer.cornerRadius = 5
                
            }else{
                DispatchQueue.main.async(execute: {
                print(FBSDKAccessToken.current())
                userObj?.accessToken = String(describing: FBSDKAccessToken.current()!)
                AWSService().save(userObj!)
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
                if (self.submitButton.isEnabled == false) {
                    self.dismiss(animated: true, completion: nil)
                    
                    
                    
                }

            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField!) -> Bool {
        inputUserName.resignFirstResponder()
        return true
    }
    
}
