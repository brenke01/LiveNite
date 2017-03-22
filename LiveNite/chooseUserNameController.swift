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
import AWSDynamoDB
import SCLAlertView



class ChooseUserNameController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate{
    
    @IBOutlet var userNameText: UITextField!
    
    var userID : String = ""
    
    @IBAction func submitUserName(_ sender: AnyObject) {
        print("submit")
        self.findUsername(completion: {(result)->Void in
            if (result.count > 1){
                SCLAlertView().showError("Sorry", subTitle: "That username is taken. Please choose another username")
            }else{
                
            }
        })
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
    
    func findUsername(completion:@escaping ([User])->Void)->[User]{
        
        var userArray = [User]()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.filterExpression = "userName = :val"
        scanExpression.expressionAttributeValues = [":val": userNameText.text]
    
        
        
        
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
    
}
