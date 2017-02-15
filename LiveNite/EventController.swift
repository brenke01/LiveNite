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
    var activityIndicator = UIActivityIndicatorView()
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
    var arrayEmpty = false
    var selectedEvent = Event()
    var selectedEventImg = UIImage()
    var uiImageDict = [String:UIImage]()
    var sortedUIImageArray = [UIImage]()
    var emptyArrayLabel = UILabel()
    var tryAgainButton = UILabel()
    @IBAction func addEvent(_ sender: AnyObject) {
        
        self.performSegue(withIdentifier: "addEvent", sender: 1)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "addEvent"{
            
            if let destinationVC = segue.destination as? PickLocationController{
                destinationVC.locations = 1
                destinationVC.userName = (self.user?.userID)!
                destinationVC.fromEvent = true
                destinationVC.user = self.user
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
        self.refreshControl.tintColor = UIColor.white

        self.tableView.addSubview(self.refreshControl)

        self.tableView.backgroundColor = UIColor.clear
        if #available(iOS 8.0, *) {
            self.locationManager.requestWhenInUseAuthorization()
        } else {
            // Fallback on earlier versions
        }
        self.tableView.backgroundView = UIImageView(image: UIImage(named: "backgroundimg"))
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
        getEventData()

    }
    
    func getEventData(){
        progressBarDisplayer("Loading", true)
        self.getEvents(completion: {(result)->Void in
            DispatchQueue.main.async(execute: {
               
                if (self.eventsArr.count == 0){
                    self.arrayEmpty = true
                    self.tableView.reloadData()
                }else{
                     self.determineSort()
                    self.arrayEmpty = false
                    for e in self.eventsArr{
                        AWSService().getImageFromUrl(String(e.url), completion: {(result)->Void in
                            self.uiImageArr.append(result)
                            if self.uiImageArr.count == self.eventsArr.count{
                                DispatchQueue.main.async(execute: {
                                    self.uiImageDict = self.createUIImageDict()
                                    
                                    
                                    self.tableView!.reloadData()
                                    
                                })
                            }
                        })
                    }
                }
                
                
            })
        })
    }
    
    func progressBarDisplayer(_ msg:String, _ indicator:Bool ) {

        if indicator {
            
            
            activityIndicator.frame = CGRect(x:self.view.frame.midX - 50, y: self.view.frame.midY - 100, width: 100, height: 100)
            activityIndicator.startAnimating()

        }

        self.tableView?.addSubview(activityIndicator)
    }
    
    func createUIImageDict() -> [String: UIImage]{
        var dict = [String: UIImage]()
        for i in 0...self.eventsArr.count-1{
            
            dict[self.eventsArr[i].eventID] = self.uiImageArr[i]
            
        }
        return dict
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
            determineSort()
            self.tableView.reloadData()
        }else{
            sortButton.setTitle("Recent", for: UIControlState())
            self.hotToggle = 0
            determineSort()
            self.tableView.reloadData()
        }
    }
    
    func determineSort(){
        if (self.hotToggle == 1){
            self.eventsArr = (self.eventsArr as NSArray).sortedArray(using: [
                NSSortDescriptor(key: "totalScore", ascending: false)
                ]) as! [Event]
        }else{
            
            self.eventsArr = (self.eventsArr as NSArray).sortedArray(using: [
                NSSortDescriptor(key: "timePosted", ascending: false)
                ]) as! [Event]
        }
        
    }
    
    func handleRefresh(_ refreshControl: UIRefreshControl){
        self.getEvents(completion: {(result)->Void in
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
                
            })
        })
        refreshControl.endRefreshing()
    }
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        return refreshControl
    }()

    
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
        if (self.arrayEmpty){
            return 1
        }else{
            return self.eventsArr.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as UITableViewCell
        cell.backgroundColor = UIColor.clear
        cell.selectionStyle = UITableViewCellSelectionStyle.none

        if (self.uiImageArr.count > 0){
            cell.backgroundColor = UIColor.clear

            
        let imageButton = UIButton(frame: CGRect(x: self.view.frame.width * 0.05, y: self.view.frame.height * 0.05, width: CGFloat(self.view.frame.width * 0.9), height: self.view.frame.height * 0.3))
            imageButton.layer.cornerRadius = 10

            let titleView = UILabel(frame: CGRect(x: 5, y: imageButton.frame.height * 0.9, width: imageButton.frame.width, height: imageButton.frame.height * 0.1))
            
            
            titleView.text = self.eventsArr[indexPath.row].eventTitle
            titleView.textColor = UIColor.white
            titleView.backgroundColor = UIColor.darkGray
            titleView.font = UIFont (name: "HelveticaNeue-Bold", size: 12)
            imageButton.addSubview(titleView)
            imageButton.isUserInteractionEnabled = true
            imageButton.layer.masksToBounds = true
            let imageScoreLabel  = UILabel(frame: CGRect(x: imageButton.frame.width * 0.9, y: imageButton.frame.height - imageButton.frame.height * 0.2, width: self.view.frame.width * 0.20, height: 40))
            let imageLabelContainer = UILabel(frame: CGRect(x: 0, y: imageButton.frame.height - imageButton.frame.height * 0.2, width: imageButton.frame.width, height: 40))
            imageLabelContainer.backgroundColor = UIColor.darkGray
            imageScoreLabel.textColor = UIColor.white
            imageScoreLabel.backgroundColor = UIColor.darkGray
            imageScoreLabel.text = String(self.eventsArr[indexPath.row].hotColdScore)
            imageButton.addSubview((titleView))
            imageButton.isUserInteractionEnabled = true
            imageButton.layer.masksToBounds = true
            imageButton.setImage(self.uiImageDict[self.eventsArr[indexPath.row].eventID], for: UIControlState())
            cell.addSubview(imageButton)
            let imagePressed :Selector = #selector(ViewController.imagePressed(_:))
            let tap = UITapGestureRecognizer(target: self, action: imagePressed)
            tap.cancelsTouchesInView = false
            tap.numberOfTapsRequired = 1
            imageButton.addGestureRecognizer(tap)
            cell.layer.cornerRadius = 5
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
        }else if (self.arrayEmpty){

                self.activityIndicator.stopAnimating()
                self.activityIndicator.removeFromSuperview()
                self.emptyArrayLabel = UILabel(frame: CGRect(x: 0, y: ((self.tableView?.frame.height)! / 2) - 75, width: self.view.frame.width, height: 50))
                self.tryAgainButton = UILabel(frame: CGRect(x: 0, y: ((self.tableView?.frame.height)! / 2) - 50, width: self.view.frame.width, height: 50))
                self.tryAgainButton.text = "Tap to retry"
                self.tryAgainButton.textAlignment = .center
                self.tryAgainButton.textColor = UIColor.white
                self.tryAgainButton.layer.masksToBounds = true
                
                self.emptyArrayLabel.text = "No posts found"
                self.tryAgainButton.font = UIFont.boldSystemFont(ofSize: 16)
                self.emptyArrayLabel.textColor = UIColor.white
                self.emptyArrayLabel.textAlignment = .center
                self.activityIndicator.stopAnimating()
                self.activityIndicator.removeFromSuperview()
                
                cell.addSubview(self.tryAgainButton)
                cell.addSubview(self.emptyArrayLabel)
         

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
        if (self.arrayEmpty){
            self.emptyArrayLabel.removeFromSuperview()
            self.tryAgainButton.removeFromSuperview()
            getEventData()
        }
        
    }
    
   func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath)-> CGFloat{
        if (self.arrayEmpty){
            return self.view.frame.height
        }else{
            return 240
        }
    }
    
    func tableView(tableView:UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: IndexPath){
        cell.backgroundColor = UIColor.clear
    }
    
    override func viewDidAppear(_ animated: Bool){
        self.getEvents(completion: {(result)->Void in
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
                
            })
        })
        super.viewDidAppear(animated)
    }

}
