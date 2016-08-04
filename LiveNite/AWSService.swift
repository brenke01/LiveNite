//
//  AWSService.swift
//  LiveNite
//
//  Created by Kevin  on 7/24/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//

import Foundation
import AWSDynamoDB
class AWSService {
    
    func save(myObject : AnyObject){
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        dynamoDBObjectMapper.save(myObject as! AWSDynamoDBObjectModel).continueWithBlock({(task: AWSTask) -> AnyObject in
            if ((task.error) != nil){
                print("error: \(task.error)")
            }
            if ((task.exception) != nil){
                print("exception: \(task.exception)")
            }
            if ((task.result) != nil){
                print("save")
            }
            return "success"
        })
    }
    
    //Retrieving 
    func loadImage(primaryKeyValue: String) -> Image{
        var image : Image = Image()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        dynamoDBObjectMapper.load(Image.self, hashKey: primaryKeyValue, rangeKey: nil).continueWithBlock({(task: AWSTask) -> AnyObject in
            if (task.error != nil){
                print("error")
    
            }
            if (task.exception != nil){
                print("exception")
            }
            if (task.result != nil){
                
                image = task.result as! Image
            }
            return image
        })
        return image
    }
}
