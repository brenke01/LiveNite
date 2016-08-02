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
    

    
    
    func saveImage(myImage : Image){
        var dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
    dynamoDBObjectMapper.save(myImage).continueWithBlock({(task: AWSTask) -> AnyObject in
    if ((task.error) != nil){
    print("error")
    }
    if ((task.exception) != nil){
    print("exception")
    }
    if ((task.result) != nil){
    print("save")
    }
    return "success"
        })
    }
  
}
