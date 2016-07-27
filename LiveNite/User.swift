//
//  User.swift
//  LiveNite
//
//  Created by Kevin  on 6/10/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//

import Foundation
import AWSDynamoDB

class User :AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var userID: Int
    var userName: String
    var gender: String
    var age: Int
    var email: String
    var score: Int
    var accessToken: String
    
    class func dynamoDBTableName() -> String{
        return "Users"
    }
    
    class func primaryKeyAttribute() -> String{
        return "userID"
    }
}

    