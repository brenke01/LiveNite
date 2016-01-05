//
//  PickLocation.swift
//  LiveNite
//
//  Created by Kevin on 1/3/16.
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

class PickLocationController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout{
    
    var locations = 1
    var complete = false
    let captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    var captureDevice : AVCaptureDevice?
    override func viewDidLoad() {
        super.viewDidLoad()
        print("pick location")
        
        
    }
    func takeAndSave(){
        //locationManager.startUpdatingLocation()
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            
            print("captureVideoPressed and camera available.")
            
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            imagePicker.sourceType = .Camera;
            //imagePicker.mediaTypes = [kUTTypeMovie!]
            imagePicker.allowsEditing = false
            
            imagePicker.showsCameraControls = true

            self.presentViewController(imagePicker, animated: true, completion: nil)
            complete = true
        }
            
        else {
            print("Camera not available.")
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info:[String : AnyObject]) {
        
        
        
        if let newVideo = NSEntityDescription.insertNewObjectForEntityForName("Entity", inManagedObjectContext:context) as? NSManagedObject{
            let tempImage = info[UIImagePickerControllerOriginalImage] as! UIImage;
            let dataImage:NSData = UIImageJPEGRepresentation(tempImage, 0.0)!
            newVideo.setValue(dataImage, forKey: "videoData")
            var date = NSDate()
            var calendar = NSCalendar.currentCalendar()
            var components = calendar.components([.Hour, .Minute], fromDate: date)
            var hourOfDate = components.hour
            newVideo.setValue(hourOfDate, forKey: "time")
            var setImageTitle : String = "Fun at Blarneys"
            var setUpVotes : Int = 0
            var setId : Int = getImageId()
            print(setId, terminator: "")
            newVideo.setValue(setId, forKey: "id")
            newVideo.setValue(setUpVotes, forKey: "upvotes")
            newVideo.setValue(setImageTitle, forKey: "title")
            do {
                try context.save()
            } catch _ {
            }
            print("saved successfully", terminator: "")
            
            dismissViewControllerAnimated(true, completion: nil)
            
            //locationManager.stopUpdatingLocation()
            //self.collectionView!.reloadData()
            
            
            
        }
        
        //fetchNearbyPlaces(userLocation)
        
        
    }
    
    func getImageId()-> Int{
        var currentID = 1
        let fetchRequest = NSFetchRequest(entityName: "CurrentID")
        let locations = (try? context.executeFetchRequest(fetchRequest)) as! [NSManagedObject]?
        if let locations = locations{
            for loc in locations{
                let idData : AnyObject? = loc.valueForKey("id")
                if (idData == nil){
                    currentID = 1
                }else{
                    currentID = (idData as? Int)!
                }
                
                
                
            }}
        if let newId = NSEntityDescription.insertNewObjectForEntityForName("CurrentID", inManagedObjectContext:context) as? NSManagedObject{
            currentID = currentID + 1
            newId.setValue(currentID, forKey: "id")
            do {
                try context.save()
            } catch _ {
            }
        }
        return currentID
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print("view appeared")
        if (complete == false){
            takeAndSave()
        }else{
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    
}