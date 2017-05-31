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
    
    var notificationID = ""
    var ownerName: String = ""
    var userName: String = ""
    var open = false
    var actionTime = ""
    var imageID = ""
    var type = ""
    var expirationDate = 0
    
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
