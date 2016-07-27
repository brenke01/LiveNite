//
//  Image.swift
//  LiveNite
//
//  Created by Jacob Pierce on 7/27/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//

import Foundation
import AWSDynamoDB

class Image :AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    
    var timePosted : String
    var picTakenLat : Double
    var picTakenLong : Double
    var placeLat : Double
    var placeLong : Double
    var hotColdScore : Double
    var imageID : Int
    var totalScore : Int
    var url : String
    var placeTitle : String
    var caption : String
    var owner : String
    var eventID : Int
    
    class func dynamoDBTableName() -> String{
        return "Images"
    }
    
    class func primaryKeyAttribute() -> String{
        return "imageID"
    }
}
