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
    
    var imageID: String = ""
    var timeVoted: String = ""
    var voteValue: Int = 0
    var ownerName: String = ""
    var voteID: String = ""
    
    class func dynamoDBTableName() -> String{
        return "Votes"
    }
    
    class func primaryKeyAttribute() -> String{
        return "voteID"
    }
    
    class func hashKeyAttribute() -> String {
        return "voteID"
    }
    
}
