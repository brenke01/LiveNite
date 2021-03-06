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
    
    var userID: String = ""
    var userName: String = ""
    var gender: String = ""
    var age: Int = 0
    var email: String = ""
    var score: Int = 0
    var accessToken: String = ""
    var distance = 10
    var profileImg = ""
    
    class func dynamoDBTableName() -> String{
        return "Users"
    }
    
    class func primaryKeyAttribute() -> String{
        return "userID"
    }
    
    class func hashKeyAttribute() -> String {
        return "userID"
    }
}

    
