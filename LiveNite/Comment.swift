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
    
    class func dynamoDBTableName() -> String{
        return "Comments"
    }
    
    class func primaryKeyAttribute() -> String{
        return ""
    }
}
