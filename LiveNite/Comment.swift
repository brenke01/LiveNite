//
//  Comment.swift
//  LiveNite
//
//  Created by Jacob Pierce on 7/27/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//

import Foundation
import AWSDynamoDB

class Comment :AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var comment: String = ""
    var imageID: Int = 0
    var owner: String = ""
    var timePosted: String = ""
    var commentID: Int = 0
    var eventID: Int = 0
    
    class func dynamoDBTableName() -> String{
        return "Comments"
    }
    
    class func primaryKeyAttribute() -> String{
        return "commentID"
    }
    
    class func hashKeyAttribute() -> String {
        return ""
    }
}
