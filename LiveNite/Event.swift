//
//  Event.swift
//  LiveNite
//
//  Created by Jacob Pierce on 7/27/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//

import Foundation
import AWSDynamoDB

class Event :AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var eventLat: Double = 0
    var eventLong: Double = 0
    var publicStatus: Bool = false
    var eventStartTime: String = ""
    var eventEndTime: String = ""
    var placeTitle: String = ""
    var eventTitle: String = ""
    var information: String = ""
    var hotColdScore: Double = 0
    var eventID: String = ""
    var url: String = ""
    var timePosted: String = ""
    
    class func dynamoDBTableName() -> String{
        return "Events"
    }
    
    class func primaryKeyAttribute() -> String{
        return "eventID"
    }
    
    class func hashKeyAttribute() -> String {
        return "eventID"
    }
}
