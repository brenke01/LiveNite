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
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "Background_Gradient")!)
        let loginView : FBSDKLoginButton = FBSDKLoginButton()
        self.view.addSubview(loginView)
        loginView.center = self.view.center
        loginView.readPermissions = ["public_profile", "email"]
        loginView.delegate = self
        
        
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
        
        let fetchRequest = NSFetchRequest(entityName: "Users")
        //The result from the Facebook request is an object that works like a Dictionary 
        //First we grab all of the fields
        let userID = result.valueForKey("id") as! AnyObject?
        let firstName = result.valueForKey("first_name") as! AnyObject?
        let gender = result.valueForKey("gender") as! AnyObject?
        let ageRange = result.valueForKey("age_range")?.valueForKey("min") as! AnyObject?
        //This is our predicate for the table that will ask for a record that has an id of userID
        
        fetchRequest.predicate = NSPredicate(format: "id= %i", userID as! NSString)
        let user = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        //If the fetch request returns nothing, we know that they are a new user
        if (user! == []){
            //This is how you declare your "table"
            if let newUser = NSEntityDescription.insertNewObjectForEntityForName("Users", inManagedObjectContext:context) as? NSManagedObject{
                
                //For each "column" set your values
                newUser.setValue(userID as! NSString, forKey: "id")
                newUser.setValue(firstName as! NSString, forKey: "first_name")
                newUser.setValue(gender as! NSString, forKey: "gender")
                newUser.setValue(ageRange as! Int, forKey: "age")
                do {
                    try context.save()
                } catch _ {
                }

            }
        }
    }
    func returnUserData()
    {
        //The graphRequest is Facebooks Graph API. If you want to grab more parameters, look up the fields
        // on their documentation and add them
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, first_name, gender, age_range"])
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if ((error) != nil)
            {
                // Process error
                print("Error: \(error)")

            }
            else
            {   //Save the user to the Users table
                self.saveUserToCoreData(result)
                
                self.dismissViewControllerAnimated(true, completion: nil)
                print("fetched user: \(result)")
                let userGender : NSString = result.valueForKey("gender") as! NSString
                print("User gender is: \(userGender)")
                

            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
