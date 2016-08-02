//
//  CheckIn.swift
//  LiveNite
//
//  Created by Jacob Pierce on 7/27/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//

import Foundation
import AWSDynamoDB

class CheckIn :AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var checkInTime: String = ""
    var placeTitle: String = ""
    var user: String = ""
    var checkInID: Int = 0
    
    class func dynamoDBTableName() -> String{
        return "CheckIns"
    }
    
    class func primaryKeyAttribute() -> String{
        return "checkInID"
    }
    
    class func hashKeyAttribute() -> String {
        return ""
    }
}