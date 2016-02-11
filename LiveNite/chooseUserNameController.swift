//
//  ChooseUserNameController.swift
//  
//
//  Created by Jacob Pierce on 2/9/16.
//
//

import UIKit
import MediaPlayer
import MobileCoreServices
import AVFoundation
import CoreData
import CoreLocation
import GoogleMaps



class ChooseUserNameController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate{
    
    @IBOutlet var userNameText: UITextField!
    
    var userID : String = ""
    
    @IBAction func submitUserName(sender: AnyObject) {
        print("submit")
        let fetchRequest = NSFetchRequest(entityName: "Users")
        fetchRequest.predicate = NSPredicate(format: "id= %@", userID as NSString)
        let users = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        if let users = users{
            for user in users{
                user.setValue(userNameText.text, forKey: "user_name")
                do {
                    try context.save()
                } catch _ {
                }
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        } else {
            print("User Name storage failed")
            self.dismissViewControllerAnimated(true, completion: nil)   
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(userID)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        userNameText.resignFirstResponder()
        return true
    }
    
}