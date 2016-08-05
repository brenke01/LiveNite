//
//  AWSService.swift
//  LiveNite
//
//  Created by Kevin  on 7/24/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//

import Foundation
import AWSDynamoDB
import AWSS3
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
    
    func saveImageToBucket (selectedImage : NSData, id : Int){
        var transferManager: AWSS3TransferManager = AWSS3TransferManager.defaultS3TransferManager()
        var uploadRequest : AWSS3TransferManagerUploadRequest = AWSS3TransferManagerUploadRequest()
let testFileURL1 = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("temp")
        selectedImage.writeToURL(testFileURL1, atomically: true)
        uploadRequest.bucket = "liveniteimages"
        uploadRequest.key = String(id)
        uploadRequest.body = testFileURL1
        transferManager.upload(uploadRequest).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: {(task: AWSTask) -> AnyObject in
            if (task.error != nil) {
                if (task.error!.domain == AWSS3TransferManagerErrorDomain) {
                    switch task.error!.code {

             
                    default:
                        print("Error: \(task.error)")
                    }
                }
                else {
                    // Unknown error.
                    print("Error: \(task.error)")
                }
            }
            if (task.result != nil) {
                var uploadOutput: AWSS3TransferManagerUploadOutput = task.result as! AWSS3TransferManagerUploadOutput
                // The file uploaded successfully.
                // The file uploaded successfully.
            }
            return "success"
        })
    }
}
