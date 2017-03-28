//
//  MeetUp.swift
//  LiveNite
//
//  Created by Jacob Pierce on 3/27/17.
//  Copyright © 2017 LiveNite. All rights reserved.
//

import Foundation
import AWSDynamoDB

class MeetUp :AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var meetUpTime: String = ""
    var user1ID: String = ""
    var user2ID: String = ""
    var meetUpID: String = ""
    
    class func dynamoDBTableName() -> String{
        return "MeetUps"
    }
    
    class func primaryKeyAttribute() -> String{
        return "meetUpID"
    }
    
    class func hashKeyAttribute() -> String {
        return "meetUpID"
    }
}

