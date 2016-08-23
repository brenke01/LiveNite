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
    
    func loadCheckIn(primaryKeyValue: String) -> CheckIn{
        var checkIn : CheckIn = CheckIn()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        dynamoDBObjectMapper.load(CheckIn.self, hashKey: primaryKeyValue, rangeKey: nil).continueWithBlock({(task: AWSTask) -> AnyObject in
            if (task.error != nil){
                print("error")
                
            }
            if (task.exception != nil){
                print("exception")
            }
            if (task.result != nil){
                
                checkIn = task.result as! CheckIn
            }
            return checkIn
        })
        return checkIn
    }
    
    func loadComment(primaryKeyValue: String) -> Comment{
        var comment : Comment = Comment()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        dynamoDBObjectMapper.load(Comment.self, hashKey: primaryKeyValue, rangeKey: nil).continueWithBlock({(task: AWSTask) -> AnyObject in
            if (task.error != nil){
                print("error")
                
            }
            if (task.exception != nil){
                print("exception")
            }
            if (task.result != nil){
                
                comment = task.result as! Comment
            }
            return comment
        })
        return comment
    }
    
    func loadEvent(primaryKeyValue: String) -> Event{
        var event : Event = Event()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        dynamoDBObjectMapper.load(Event.self, hashKey: primaryKeyValue, rangeKey: nil).continueWithBlock({(task: AWSTask) -> AnyObject in
            if (task.error != nil){
                print("error")
                
            }
            if (task.exception != nil){
                print("exception")
            }
            if (task.result != nil){
                
                event = task.result as! Event
            }
            return event
        })
        return event
    }
    
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
    

    // Retrieving image file from S3
    func getImageFromUrl(fileName : String) -> UIImage{
        var transferManager: AWSS3TransferManager = AWSS3TransferManager.defaultS3TransferManager()
        var downloadedImage : UIImage = UIImage()
        var downloadingFilePath: String = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("downloaded-myImage.jpg").absoluteString
        var downloadingFileURL: NSURL = NSURL.fileURLWithPath(downloadingFilePath)
        // Construct the download request.
        var downloadRequest: AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest.bucket = "liveniteimages"
        downloadRequest.key = fileName
        downloadRequest.downloadingFileURL = downloadingFileURL
        transferManager.download(downloadRequest).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: {(task: AWSTask) -> AnyObject in
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
                var downloadOutput: AWSS3TransferManagerDownloadOutput = task.result as! AWSS3TransferManagerDownloadOutput
                downloadedImage = UIImage(contentsOfFile: (downloadingFilePath))!
                //File downloaded successfully.
                //File downloaded successfully.
            }
            return downloadedImage
        })
        return downloadedImage
    }
    
    func loadUser(primaryKeyValue: String, newUserName : String) -> User{
        var user : User = User()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        dynamoDBObjectMapper.load(User.self, hashKey: primaryKeyValue, rangeKey: nil).continueWithBlock({(task: AWSTask) -> AnyObject in
            if (task.error != nil){
                print("error")
                
                
            }
            if (task.exception != nil){
                print("exception")
            }
            if (task.result != nil){
                
                user = task.result as! User
                if (newUserName != ""){
                    user.userName = newUserName
                    AWSService().save(user)
                }
            }
            return user
        })
        return user
    }
    
    func loadUserAndSaveUserName(primaryKeyValue: String, newUserName : String) -> User{
        var user : User = User()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        dynamoDBObjectMapper.load(User.self, hashKey: primaryKeyValue, rangeKey: nil).continueWithBlock({(task: AWSTask) -> AnyObject in
            if (task.error != nil){
                print("error")
                
                
            }
            if (task.exception != nil){
                print("exception")
            }
            if (task.result != nil){
                
                user = task.result as! User
            }
            return user
        })
        return user
    }
    
    
    
    func loadVote(primaryKeyValue: String) -> Vote{
        var vote : Vote = Vote()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        dynamoDBObjectMapper.load(Vote.self, hashKey: primaryKeyValue, rangeKey: nil).continueWithBlock({(task: AWSTask) -> AnyObject in
            if (task.error != nil){
                print("error")
                
            }
            if (task.exception != nil){
                print("exception")
            }
            if (task.result != nil){
                
                vote = task.result as! Vote
            }
            return vote
        })
        return vote
    }
    
    func saveImageToBucket (selectedImage : NSData, id : String, placeName: String) -> String{
        var transferManager: AWSS3TransferManager = AWSS3TransferManager.defaultS3TransferManager()
        var uploadRequest : AWSS3TransferManagerUploadRequest = AWSS3TransferManagerUploadRequest()
let testFileURL1 = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("temp")
        selectedImage.writeToURL(testFileURL1, atomically: true)
        uploadRequest.bucket = "liveniteimages"
        uploadRequest.key = id + "_" + placeName
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
           return uploadRequest.key!
        })
        return "success"
    }
    
}
