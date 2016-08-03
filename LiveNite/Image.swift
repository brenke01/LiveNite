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
    
    var timePosted : String = ""
    var picTakenLat : Double = 0
    var picTakenLong : Double = 0
    var placeLat : Double = 0
    var placeLong : Double = 0
    var hotColdScore : Double = 0
    var imageID : Int = 0
    var totalScore : Int = 0
    var url : String = ""
    var placeTitle : String = ""
    var caption : String = ""
    var owner : String = ""
    var eventID : Int = 0
    
    class func dynamoDBTableName() -> String{
        return "Images"
    }
    
    class func primaryKeyAttribute() -> String{
        return "imageID"
    }
    
    class func hashKeyAttribute() -> String {
        return "imageID"
    }
}
