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
import AWSDynamoDB

class EventController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout,  CLLocationManagerDelegate{

    @IBOutlet weak var tableView: UITableView!
    var user = User()
    var userID = ""
    
    var bounds = [CLLocation]()
    var nearbyZipCodes = [String]()
    var data = Data()
    var geoHashArr:[String] = []
    var userLocation = CLLocationCoordinate2D()
    var locationUpdated = false
    var uiImageArr = [UIImage]()
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
    
    func getEvents(completion:@escaping ([Event])->Void)->[Event]{
        //sendGeo()
        var eventsArray = [Event]()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        let radius : Int = 5
        let latTraveledDeg : Double = (1 / 110.54) * Double(radius)
        var locationManager = CLLocationManager()
        if #available(iOS 8.0, *) {
            locationManager.requestWhenInUseAuthorization()
        } else {
            // Fallback on earlier versions
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.stopUpdatingLocation()
        let loc :  CLLocationCoordinate2D = locationManager.location!.coordinate
        let  longTraveledDeg : Double = (1 / (111.320 * cos(loc.latitude)))
        let latBoundPos = loc.latitude + latTraveledDeg
        let latBoundNeg = loc.latitude - latTraveledDeg
        let longBoundPos = loc.longitude + longTraveledDeg
        let longBoundNeg = loc.longitude - longTraveledDeg
        self.bounds = [CLLocation(latitude: latBoundPos, longitude: longBoundPos), CLLocation(latitude: latBoundPos, longitude: longBoundNeg), CLLocation(latitude: latBoundNeg, longitude: longBoundPos), CLLocation(latitude: latBoundNeg, longitude: longBoundNeg)]
        
        
        for i in self.bounds{
            
            var geo :Geohash = Geohash()
            let l = CLLocationCoordinate2DMake(i.coordinate.latitude, i.coordinate.longitude)
            let s = l.geohash(10)
            self.geoHashArr.append(s)
            
            
        }
        
        
        queryExpression.indexName = "geohash-index"
        queryExpression.hashKeyAttribute = "geohash"
        queryExpression.hashKeyValues = self.geoHashArr[0].substring(to: self.geoHashArr[0].characters.index(self.geoHashArr[0].endIndex, offsetBy: -7))
        
        
        dynamoDBObjectMapper.query(Event.self, expression: queryExpression).continue({(task: AWSTask) -> AnyObject in
            if (task.error != nil) {
                print("The request failed. Error: [\(task.error)]")
            }
            if (task.exception != nil) {
                print("The request failed. Exception: [\(task.exception)]")
            }
            if (task.result != nil) {
                let output : AWSDynamoDBPaginatedOutput = task.result!
                for e  in output.items {
                    let event : Event = e as! Event
                    eventsArray.append(event)
                }
                completion(eventsArray)
                return eventsArray as AnyObject
                
            }
            return eventsArray as AnyObject
        })
        
        
        return eventsArray

    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section : Int) -> Int{
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as UITableViewCell
        cell.backgroundColor = UIColor.black
          self.uiImageArr = []
        let imageButton = UIButton(frame: CGRect(x: 0, y: 0, width: CGFloat(self.view.frame.width), height: CGFloat(self.view.frame.height * 0.3)))
        imageButton.setImage(self.uiImageArr[(indexPath as NSIndexPath).row], for: UIControlState())
        return cell
    }
    
    func tableView(_ tableView : UITableView, didSelectRowAtIndexPath indexPath: IndexPath){
        
    }
    
}
