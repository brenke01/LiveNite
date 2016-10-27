//
//  EventController.swift
//  LiveNite
//
//  Created by Kevin  on 9/14/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer
import MobileCoreServices
import AVFoundation
import CoreData
import CoreLocation
import GoogleMaps

class EventController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout,  CLLocationManagerDelegate{

    @IBOutlet weak var tableView: UITableView!
    var user = User()
    var userID = ""
    @IBAction func addEvent(_ sender: AnyObject) {
        
        self.performSegue(withIdentifier: "addEvent", sender: 1)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "addEvent"{
            
            if let destinationVC = segue.destination as? PickLocationController{
                
                destinationVC.locations = 1
                destinationVC.userName = (self.user?.userID)!
                destinationVC.fromEvent = true
            }
        }
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        if (self.user?.userID == ""){
            retrieveUserID({(result)->Void in
                self.userID = result
                AWSService().loadUser(self.userID,completion: {(result)->Void in
                    self.user = result
                    
                })
                
            })
        }
    }
    
    func retrieveUserID(_ completion:@escaping (_ result: String)->Void){
        var id = ""
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, first_name, gender, age_range"])
        graphRequest.start(completionHandler: { (connection, result, error) -> Void in
            
            if ((error) != nil)
            {
                // Process error
                print("Error: \(error)")
                
            }else{
                let data:[String:AnyObject] = result as! [String: AnyObject]
                let userID = data["id"] as? String
                completion(userID!)
                
            }
            
        })
        
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section : Int) -> Int{
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell{
        return UITableViewCell()
    }
    
    func tableView(_ tableView : UITableView, didSelectRowAtIndexPath indexPath: IndexPath){
        
    }
    
}
