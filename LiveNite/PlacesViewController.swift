//
//  PlacesViewController.swift
//  LiveNite
//
//  Created by Jacob Pierce on 7/9/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//

import Foundation
import CoreData
import AWSDynamoDB

class PlacesViewController{
    
    func getGroupedImages()->[Image]{
        var imagesArray = [Image]()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        var queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.hashKeyAttribute = "imageID"
        dynamoDBObjectMapper.query(Image.self, expression: queryExpression).continueWithBlock({(task: AWSTask) -> AnyObject in
            if (task.error != nil) {
                print("The request failed. Error: [\(task.error)]")
            }
            if (task.exception != nil) {
                print("The request failed. Exception: [\(task.exception)]")
            }
            if (task.result != nil) {
                var output : AWSDynamoDBPaginatedOutput = task.result as! AWSDynamoDBPaginatedOutput
                for image  in output.items {
                    let image : Image = image as! Image
                    imagesArray.append(image)
                }
                let sortedArray = (imagesArray as NSArray).sortedArrayUsingDescriptors([
                    NSSortDescriptor(key: "placeTitle", ascending: true),
                    NSSortDescriptor(key: "totalScore", ascending: true)
                    ]) as! [Image]
                return sortedArray
                
            }
            return imagesArray
        })
        return imagesArray
//        let fetchRequest = NSFetchRequest(entityName: "Entity")
//        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: false), NSSortDescriptor(key: "upvotes", ascending: false)]
//        return fetchRequest
    }
    
    func getImagesForGroup(placeName: String, user: User)->[Image]{
        
        var imagesArray = [Image]()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        var queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.hashKeyAttribute = "imageID"
        queryExpression.rangeKeyConditionExpression = "placeTitle = :val"
        queryExpression.expressionAttributeValues = [":val": placeName]
        dynamoDBObjectMapper.query(Image.self, expression: queryExpression).continueWithBlock({(task: AWSTask) -> AnyObject in
            if (task.error != nil) {
                print("The request failed. Error: [\(task.error)]")
            }
            if (task.exception != nil) {
                print("The request failed. Exception: [\(task.exception)]")
            }
            if (task.result != nil) {
                var output : AWSDynamoDBPaginatedOutput = task.result as! AWSDynamoDBPaginatedOutput
                for image  in output.items {
                    let image : Image = image as! Image
                    imagesArray.append(image)
                }
            }
            return imagesArray
        })
            // If the response lastEvaluatedKey has contents, that means there are more results
//        let fetchRequest = NSFetchRequest(entityName: "Entity")
//        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
//        fetchRequest.predicate = NSPredicate(format: "title= %@", placeName)
//        return fetchRequest
        
        return imagesArray
    }
}