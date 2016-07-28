//
//  Vote.swift
//  LiveNite
//
//  Created by Jacob Pierce on 7/27/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//

import Foundation
import AWSDynamoDB

class Vote :AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var imageID: Int = 0
    var timeVoted: String = ""
    var voteValue: Int = 0
    var owner: String = ""
    var voteID: Int = 0
    
    class func dynamoDBTableName() -> String{
        return "Votes"
    }
    
    class func primaryKeyAttribute() -> String{
        return "voteID"
    }
    
    class func hashKeyAttribute() -> String {
        return ""
    }
    
}
