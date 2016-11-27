//
//  CommentController.swift
//  LiveNite
//
//  Created by Kevin  on 6/14/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//

import Foundation
import MobileCoreServices
import CoreData
import CoreLocation
import AWSDynamoDB

class CommentController: UIViewController, UITableViewDelegate, CLLocationManagerDelegate{
    @IBAction func back(_ sender: AnyObject) {
        self.dismiss(animated: false, completion: nil)
    }
    @IBOutlet weak var navBar: UINavigationBar!
    
    @IBOutlet weak var tableView: UITableView!
    var imageID = ""
    var userNameOP = ""
    var userName = ""

}

