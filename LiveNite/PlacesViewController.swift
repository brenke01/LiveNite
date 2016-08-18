//
//  PlacesViewController.swift
//  LiveNite
//
//  Created by Jacob Pierce on 7/9/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//

import Foundation
import CoreData

class PlacesViewController{
    
    func getGroupedImages()->NSFetchRequest{
        let fetchRequest = NSFetchRequest(entityName: "Entity")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: false), NSSortDescriptor(key: "upvotes", ascending: false)]
        return fetchRequest
    }
    
    func getImagesForGroup(placeName: String, user: User)->[Image]{
        var distanceChosen = user.distanceChosen
        var imagesArray = [Image]
        var condition = DynamoDBCondition()
        condition.comparisonOperator = "EQ"
        var placeTitle: DynamoDBAttributeValue = DynamoDBAttributeValue(N: placeName)
        condition.addAttributeValueList(placeTitle)
        var queryStartKey: [NSObject : AnyObject]? = nil
        repeat {
            var queryRequest: DynamoDBQueryRequest = DynamoDBQueryRequest()
            queryRequest.tableName = "Images"
            queryRequest.exclusiveStartKey = queryStartKey!
            queryRequest.keyConditions = [
                "placeTitle" : condition
            ]
            
            var queryResponse: DynamoDBQueryResponse = Constants.ddb().query(queryRequest)
            // Each item in the result set is a NSDictionary of DynamoDBAttributeValue
            for item: [NSObject : AnyObject] in queryResponse.items {
                var image : Image = item as Image
                imagesArray.append(image)
            }
            // If the response lastEvaluatedKey has contents, that means there are more results
//        let fetchRequest = NSFetchRequest(entityName: "Entity")
//        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
//        fetchRequest.predicate = NSPredicate(format: "title= %@", placeName)
//        return fetchRequest
        }
        return imagesArray
    }
}