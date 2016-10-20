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
    
    @IBAction func submitUserName(_ sender: AnyObject) {
        print("submit")
       /* let fetchRequest = NSFetchRequest(entityName: "Users")
        fetchRequest.predicate = NSPredicate(format: "id= %@", userID as NSString)
        let users = (try? context.fetch(fetchRequest)) as! [NSManagedObject]?
        if let users = users{
            for user in users{
                user.setValue(userNameText.text, forKey: "user_name")
                do {
                    try context.save()
                } catch _ {
                }
                self.dismiss(animated: true, completion: nil)
            }
        } else {
            print("User Name storage failed")
            self.dismiss(animated: true, completion: nil)   
        }*/
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(userID)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField!) -> Bool {
        userNameText.resignFirstResponder()
        return true
    }
    
}
