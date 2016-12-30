//
//  NotificationController.swift
//  LiveNite
//
//  Created by Kevin  on 12/30/16.
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

class NotificationController: UIViewController, UITableViewDelegate, UITableViewDataSource{

    @IBOutlet weak var tableView: UITableView!
    var notificationArray = [Notification]()
    override func viewDidLoad(){
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = UIColor.white

        navigationItem.backBarButtonItem?.tintColor = UIColor.white
        navigationItem.title = "Notifications"
        tableView.delegate = self
        tableView.dataSource = self
        
  
        
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return self.notificationArray.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:NotificationCell = self.tableView.dequeueReusableCell(withIdentifier: "notificationCell")! as! NotificationCell
        

        
        return cell
    }
}

class NotificationCell: UITableViewCell{
    @IBOutlet weak var notificationLabel : UILabel!
    @IBOutlet weak var timeLabel : UILabel!
    
}
