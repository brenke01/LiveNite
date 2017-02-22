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
    
    func save(_ myObject : AnyObject){
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        dynamoDBObjectMapper.save(myObject as! AWSDynamoDBObjectModel).continue({(task: AWSTask) -> AnyObject in
            if ((task.error) != nil){
                print("error: \(task.error)")
            }
            if ((task.exception) != nil){
                print("exception: \(task.exception)")
            }
            if ((task.result) != nil){
                print("save")
            }
            return "success" as AnyObject
        })
    }
    
    func loadCheckIn(_ primaryKeyValue: String, completion:@escaping (_ result:CheckIn)->Void) -> CheckIn{
        var checkIn : CheckIn = CheckIn()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        dynamoDBObjectMapper.load(CheckIn.self, hashKey: primaryKeyValue, rangeKey: nil).continue({(task: AWSTask) -> AnyObject in
            if (task.error != nil){
                print("error")
                
            }
            if (task.exception != nil){
                print("exception")
            }
            if (task.result != nil){
                
                checkIn = task.result as! CheckIn
                completion(checkIn)
            }
            return checkIn
        })
        return checkIn
    }
    
    func loadComment(_ primaryKeyValue: String) -> Comment{
        var comment : Comment = Comment()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        dynamoDBObjectMapper.load(Comment.self, hashKey: primaryKeyValue, rangeKey: nil).continue({(task: AWSTask) -> AnyObject in
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
    
    func loadEvent(_ primaryKeyValue: String) -> Event{
        var event : Event = Event()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        dynamoDBObjectMapper.load(Event.self, hashKey: primaryKeyValue, rangeKey: nil).continue({(task: AWSTask) -> AnyObject in
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
    
    func loadImage(_ primaryKeyValue: String, completion:@escaping (_ result: Image)->Void) -> Image{
        var image : Image = Image()
        print("Image ID: " + primaryKeyValue)
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        dynamoDBObjectMapper.load(Image.self, hashKey: primaryKeyValue, rangeKey: nil).continue({(task: AWSTask) -> AnyObject in
            if (task.error != nil){
                print("error")
                
            }
            if (task.exception != nil){
                print("exception")
            }
            if (task.result != nil){


                image = task.result as! Image
                DispatchQueue.main.async(execute: {
                    completion(image)
                })
            }
            return image
        })
        return image
    }
    

    // Retrieving image file from S3
    func getImageFromUrl(_ fileName : String, completion:(_ result:UIImage)->Void) -> UIImage{
        var transferManager: AWSS3TransferManager = AWSS3TransferManager.default()
        var downloadedImage : UIImage = UIImage()
        let downloadingFilePath: String = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("FQQhOWsL.jpg").absoluteString
        let downloadingFileURL: URL = URL(fileURLWithPath: downloadingFilePath)
        // Construct the download request.
        let downloadRequest: AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest.bucket = "liveniteimages"
        let url = "https://s3.amazonaws.com/liveniteimages/" + fileName
        let urlFormat = URL(string: url)
        let imgFromURL = UIImage(data: try! Data(contentsOf: urlFormat!))
        downloadRequest.key = fileName
        //let downloadImg = UIImage(data: NSData(contentsOfURL: urlFormat!)!)
        downloadRequest.downloadingFileURL = downloadingFileURL
//        transferManager.download(downloadRequest).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: {(task: AWSTask) -> AnyObject in
//            if (task.error != nil) {
//                if (task.error!.domain == AWSS3TransferManagerErrorDomain) {
//                    switch task.error!.code {
//                        
//                        
//                    default:
//                        print("Error: \(task.error)")
//                    }
//                }
//                else {
//                    // Unknown error.
//                    print("Error: \(task.error)")
//                }
//            }
//            if (task.result != nil) {
//                var downloadOutput: AWSS3TransferManagerDownloadOutput = task.result as! AWSS3TransferManagerDownloadOutput
//                downloadedImage = UIImage(contentsOfFile: (downloadingFilePath))!
//                //File downloaded successfully.
//                //File downloaded successfully.
//                completion(result: imgFromURL!)
//            }
//            return imgFromURL!
//        })
        completion(imgFromURL!)
        return imgFromURL!
    }
    
    func loadUser(_ primaryKeyValue: String, newUserName : String) -> User{
        var user : User = User()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        dynamoDBObjectMapper.load(User.self, hashKey: primaryKeyValue, rangeKey: nil).continue({(task: AWSTask) -> AnyObject in
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
    
    func loadUser(_ primaryKeyValue: String, completion:@escaping (_ result:User)->Void) -> User{
        var user : User = User()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        dynamoDBObjectMapper.load(User.self, hashKey: primaryKeyValue, rangeKey: nil).continue({(task: AWSTask) -> AnyObject in
            if (task.error != nil){
                print("error")
                
                
            }
            if (task.exception != nil){
                print("exception")
            }
            if (task.result != nil){
                user = task.result as! User
                let vc : ViewController = ViewController()
                vc.user = user
                print("USER id is ")
                
                print(user.userID)
                DispatchQueue.main.async(execute: {
                    completion(user)
                })

            }
            return user
        })
        return user
    }
    
    func loadUserAndSaveUserName(_ primaryKeyValue: String, newUserName : String) -> User{
        var user : User = User()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        dynamoDBObjectMapper.load(User.self, hashKey: primaryKeyValue, rangeKey: nil).continue({(task: AWSTask) -> AnyObject in
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
    
    
    
    func loadVote(_ primaryKeyValue: String, completion:@escaping (_ result: Vote)->Void) -> Vote{

        var vote : Vote = Vote()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        dynamoDBObjectMapper.load(Vote.self, hashKey: primaryKeyValue, rangeKey: nil).continue({(task: AWSTask) -> AnyObject in
            if (task.error != nil){
                print("error")
                
            }
            if (task.exception != nil){
                print("exception")
            }
            if (task.result != nil){
                
                vote = task.result as! Vote
                DispatchQueue.main.async(execute: {
                    completion(vote)
                })
            }
            return vote
        })
        return vote
    }
    
    func saveImageToBucket (_ selectedImage : Data, id : String, placeName: String, completion:@escaping (_ result:String)->Void) -> String{
        let transferManager: AWSS3TransferManager = AWSS3TransferManager.default()
        let uploadRequest : AWSS3TransferManagerUploadRequest = AWSS3TransferManagerUploadRequest()
let testFileURL1 = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp")
        try? selectedImage.write(to: testFileURL1, options: [.atomic])
        uploadRequest.bucket = "liveniteimages"
        uploadRequest.key = id
        uploadRequest.body = testFileURL1
        transferManager.upload(uploadRequest).continue(with: AWSExecutor.mainThread(), with: {(task: AWSTask) -> AnyObject in
            if (task.error != nil) {
                if (task.error!._domain == AWSS3TransferManagerErrorDomain) {
                    switch task.error!._code {

             
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
                completion(uploadRequest.key!)
                // The file uploaded successfully.
                // The file uploaded successfully.
            }
           return uploadRequest.key! as AnyObject
        })
        return "success"
    }
    
    func saveProfileImageToBucket (_ selectedImage : Data, id : String, completion:@escaping (_ result:String)->Void) -> String{
        let transferManager: AWSS3TransferManager = AWSS3TransferManager.default()
        let uploadRequest : AWSS3TransferManagerUploadRequest = AWSS3TransferManagerUploadRequest()
        let testFileURL1 = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp")
        try? selectedImage.write(to: testFileURL1, options: [.atomic])
        uploadRequest.bucket = "liveniteprofileimages"
        uploadRequest.key = id
        uploadRequest.body = testFileURL1
        transferManager.upload(uploadRequest).continue(with: AWSExecutor.mainThread(), with: {(task: AWSTask) -> AnyObject in
            if (task.error != nil) {
                if (task.error!._domain == AWSS3TransferManagerErrorDomain) {
                    switch task.error!._code {
                        
                        
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
                completion(uploadRequest.key!)
                // The file uploaded successfully.
                // The file uploaded successfully.
            }
            return uploadRequest.key! as AnyObject
        })
        return "success"
    }
    
    func getProfileImageFromUrl(_ fileName : String, completion:(_ result:UIImage)->Void) -> UIImage{
        var transferManager: AWSS3TransferManager = AWSS3TransferManager.default()
        var downloadedImage : UIImage = UIImage()
        let downloadingFilePath: String = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("FQQhOWsL.jpg").absoluteString
        let downloadingFileURL: URL = URL(fileURLWithPath: downloadingFilePath)
        // Construct the download request.
        let downloadRequest: AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest.bucket = "liveniteprofileimages"
        let url = "https://s3.amazonaws.com/liveniteprofileimages/" + fileName
        let urlFormat = URL(string: url)
        let imgFromURL = UIImage(data: try! Data(contentsOf: urlFormat!))
        downloadRequest.key = fileName
        //let downloadImg = UIImage(data: NSData(contentsOfURL: urlFormat!)!)
        downloadRequest.downloadingFileURL = downloadingFileURL

        completion(imgFromURL!)
        return imgFromURL!
    }
    
    func getOpenNotifications(userName : String, completion:@escaping ([Notification])->Void)->[Notification]{
        
        var notificationArray = [Notification]()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.indexName = "ownerName-index"
        queryExpression.hashKeyAttribute = "ownerName"
        queryExpression.hashKeyValues = userName

        
        
        dynamoDBObjectMapper.query(Notification.self, expression: queryExpression).continue({(task: AWSTask) -> AnyObject in
            if (task.error != nil) {
                print("The request failed. Error: [\(task.error)]")
            }
            if (task.exception != nil) {
                print("The request failed. Exception: [\(task.exception)]")
            }
            if (task.result != nil) {
                let output : AWSDynamoDBPaginatedOutput = task.result!
                for notification  in output.items {
                    let notification : Notification = notification as! Notification
                    if (notification.open == true){
                        notificationArray.append(notification)
                    }
                }
                completion(notificationArray)
                return notificationArray as AnyObject
                
            }
            return notificationArray as AnyObject
        })
        
        
        return notificationArray
        
    }

    
}
