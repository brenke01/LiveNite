//
//  ViewEventController.swift
//  LiveNite
//
//  Created by Kevin  on 11/7/16.
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
import AWSS3

class ViewEventController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate{
    
    @IBOutlet weak var eventImg: UIImageView!
    @IBOutlet weak var eventTitleLabel: UILabel!
    var selectedEvent = Event()
    var img = UIImage()
    var user = User()
    override func viewDidLoad(){
        super.viewDidLoad()
        eventImg.image = img
        eventTitleLabel.text = selectedEvent?.eventTitle
        
    }
    
}
