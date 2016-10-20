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
    
    override func viewDidLoad(){
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
