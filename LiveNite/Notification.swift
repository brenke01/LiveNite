//
//  Notification.swift
//  LiveNite
//
//  Created by Kevin  on 12/30/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//

import Foundation
import AWSDynamoDB

class Notification :AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var userID: String = ""
    var userName: String = ""
    var open = false
    var actionTime = ""
    var imageID = ""
    
    class func dynamoDBTableName() -> String{
        return "Notifications"
    }
    
    class func primaryKeyAttribute() -> String{
        return "notificationID"
    }
    
    class func hashKeyAttribute() -> String {
        return "notificationID"
    }
}
