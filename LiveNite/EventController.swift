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

class EventController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout,  CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource{

    @IBOutlet weak var sortButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    var user = User()
    var userID = ""
    var eventsArr = [Event]()
    var bounds = [CLLocation]()
    var nearbyZipCodes = [String]()
    var data = Data()
    var locationManager = CLLocationManager()
    var geoHashArr:[String] = []
    var userLocation = CLLocationCoordinate2D()
    var locationUpdated = false
    var uiImageArr = [UIImage]()
    var hotToggle = 0
    var selectedEvent = Event()
    var selectedEventImg = UIImage()
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
        }else if segue.identifier == "viewEvent"{
            
            if let destinationVC = segue.destination as? ViewEventController{
                destinationVC.user = (self.user)!
                destinationVC.selectedEvent = self.selectedEvent
                destinationVC.img = self.selectedEventImg
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool){
        self.navigationController?.setNavigationBarHidden(true , animated: animated)
        super.viewWillAppear(animated)
    }
    override func viewWillDisappear(_ animated: Bool){
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }
    
    @IBOutlet weak var topNavBar: UIView!
    override func viewDidLoad(){
        super.viewDidLoad()
        
        self.tableView.backgroundColor = UIColor.clear
        if #available(iOS 8.0, *) {
            self.locationManager.requestWhenInUseAuthorization()
        } else {
            // Fallback on earlier versions
        }
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "backgroundimg" )!)
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.stopUpdatingLocation()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        if (self.user?.userID == ""){
            retrieveUserID({(result)->Void in
                self.userID = result
                AWSService().loadUser(self.userID,completion: {(result)->Void in
                    self.user = result
                    
                })
                
            })
        }
        
        self.getEvents(completion: {(result)->Void in
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
            
        })
        })
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
    
    @IBAction func toggleSort(_ sender: AnyObject) {
        if (self.hotToggle == 0){
            sortButton.setTitle("Popular", for: UIControlState())
            self.hotToggle = 1
            self.tableView.reloadData()
        }else{
            sortButton.setTitle("Recent", for: UIControlState())
            self.hotToggle = 0
            self.tableView.reloadData()
        }
    }
    
    func getEvents(completion:@escaping ([Event])->Void)->Void{
        //sendGeo()
        var eventsArray = [Event]()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        let radius : Int = 5
        let latTraveledDeg : Double = (1 / 110.54) * Double(radius)



        let loc :  CLLocationCoordinate2D = self.locationManager.location!.coordinate
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
                self.eventsArr = (eventsArray as AnyObject) as! [Event]

                completion(eventsArray)

                
            }
            return eventsArray as AnyObject
        })
        
        
        

    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section : Int) -> Int{
        return self.eventsArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as UITableViewCell
        cell.backgroundColor = UIColor.black
          self.uiImageArr = []
        var upVoteArray : [Int] = []
        var sortedArray = [Event]()
        if self.hotToggle == 1{
            sortedArray = (eventsArr as NSArray).sortedArray(using: [
                NSSortDescriptor(key: "hotColdScore", ascending: false)
                ]) as! [Event]
            eventsArr = sortedArray as! [Event]
        }else{
            sortedArray = (eventsArr as NSArray).sortedArray(using: [
                NSSortDescriptor(key: "timePosted", ascending: false)
                ]) as! [Event]
            eventsArr = sortedArray as! [Event]
        }
        for event in self.eventsArr{
            let titleData = event.placeTitle
         
            let eventID = event.eventID
            //Retrieving the image file from S3 example
            AWSService().getImageFromUrl(String(event.url), completion: {(result)->Void in
                
                self.uiImageArr.append(result)
                
                
            })
            
            
        }
        if (self.uiImageArr.count > 0){
            cell.backgroundColor = UIColor.clear

            
        let imageButton = UIButton(frame: CGRect(x: self.view.frame.width * 0.05, y: self.view.frame.height * 0.05, width: CGFloat(self.view.frame.width * 0.9), height: self.view.frame.height * 0.3))
            imageButton.layer.cornerRadius = 10
            let imageLabel = UILabel(frame: CGRect(x: 5, y: imageButton.frame.height - imageButton.frame.height * 0.2, width: self.view.frame.width * 0.7, height: 40))
            imageLabel.backgroundColor = UIColor.darkGray
            imageLabel.text = self.eventsArr[indexPath.row].eventTitle
            imageLabel.textColor = UIColor.white
            let imageScoreLabel  = UILabel(frame: CGRect(x: imageButton.frame.width * 0.9, y: imageButton.frame.height - imageButton.frame.height * 0.2, width: self.view.frame.width * 0.20, height: 40))
            let imageLabelContainer = UILabel(frame: CGRect(x: 0, y: imageButton.frame.height - imageButton.frame.height * 0.2, width: imageButton.frame.width, height: 40))
            imageLabelContainer.backgroundColor = UIColor.darkGray
            imageScoreLabel.textColor = UIColor.white
            imageScoreLabel.backgroundColor = UIColor.darkGray
            imageScoreLabel.text = String(self.eventsArr[indexPath.row].hotColdScore)
            imageButton.addSubview(imageLabelContainer)
            imageButton.addSubview((imageLabel))
            imageButton.addSubview(imageScoreLabel)
            imageButton.isUserInteractionEnabled = true
            imageButton.layer.masksToBounds = true
        imageButton.setImage(self.uiImageArr[(indexPath as NSIndexPath).row], for: UIControlState())
            cell.addSubview(imageButton)
            let imagePressed :Selector = #selector(ViewController.imagePressed(_:))
            let tap = UITapGestureRecognizer(target: self, action: imagePressed)
            tap.cancelsTouchesInView = false
            tap.numberOfTapsRequired = 1
            imageButton.addGestureRecognizer(tap)
            cell.layer.cornerRadius = 5
        }
        return cell
    }
    
    @IBAction func imagePressed(_ sender: UITapGestureRecognizer){
    
        let tapLocation = sender.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: tapLocation)
        self.selectedEvent = self.eventsArr[(indexPath?.row)!]
        self.selectedEventImg = self.uiImageArr[(indexPath?.row)!]
        self.performSegue(withIdentifier: "viewEvent", sender: 1)
    }
    
    func tableView(_ tableView : UITableView, didSelectRowAt indexPath: IndexPath){
        
    }
    
   func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath)-> CGFloat{
        return 240
    }
    
    func tableView(tableView:UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: IndexPath){
        cell.backgroundColor = UIColor.clear
    }
    
}
