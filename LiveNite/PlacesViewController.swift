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
import SwiftyJSON

class PlacesViewController{
    
    var bounds = [CLLocation]()
    var nearbyZipCodes = [String]()
    var data = NSData()
    
    func getGroupedImages(completion:(result:[Image])->Void)->[Image]{
        var imagesArray = [Image]()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        var scanExpression = AWSDynamoDBScanExpression()
        dynamoDBObjectMapper.scan(Image.self, expression: scanExpression).continueWithBlock({(task: AWSTask) -> AnyObject in
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
                    NSSortDescriptor(key: "placeTitle", ascending: false),
                    NSSortDescriptor(key: "totalScore", ascending: false)
                    ]) as! [Image]
                return sortedArray
                
            }
            completion(result:imagesArray)
            return imagesArray
        })
        return imagesArray
//        let fetchRequest = NSFetchRequest(entityName: "Entity")
//        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: false), NSSortDescriptor(key: "upvotes", ascending: false)]
//        return fetchRequest
    }
    
    func getNearbyZipcodes(completion: (result: Int)->Void){
        var geoCoder = CLGeocoder()
        var count = 0
      
            geoCoder.reverseGeocodeLocation(self.bounds[count], completionHandler: {(placemarks, error) -> Void in
                if (error != nil){
                    return
                }
                var placemark = placemarks![0]
                var zipcode = placemark.postalCode
                self.nearbyZipCodes.append(zipcode!)
                completion(result: self.nearbyZipCodes.count)
            })
        
       
    }
    
    
    func getImages(completion:(result:[Image])->Void)->[Image]{
        sendGeo()
        var imagesArray = [Image]()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        var queryExpression = AWSDynamoDBQueryExpression()
        let radius : Int = 5
        var latTraveledDeg : Double = (1 / 110.54) * Double(radius)
        var loc :  CLLocationCoordinate2D = CLLocationManager().location!.coordinate
        var  longTraveledDeg : Double = (1 / (111.320 * cos(loc.latitude)))
        var latBoundPos = loc.latitude + latTraveledDeg
        var latBoundNeg = loc.latitude - latTraveledDeg
        var longBoundPos = loc.longitude + longTraveledDeg
        var longBoundNeg = loc.longitude - longTraveledDeg
        self.bounds = [CLLocation(latitude: latBoundPos, longitude: longBoundPos), CLLocation(latitude: latBoundPos, longitude: longBoundNeg), CLLocation(latitude: latBoundNeg, longitude: longBoundPos), CLLocation(latitude: latBoundNeg, longitude: longBoundNeg)]
        var locationManager = CLLocationManager()
        for i in self.bounds{
            
        print(self.nearbyZipCodes.count)
        getNearbyZipcodes({
            (result)-> Void in
            if result == 4{
                
            
            
        
        queryExpression.indexName = "zipcode-index"
        queryExpression.hashKeyAttribute = "zipcode"
        queryExpression.hashKeyValues = "55416"
            
                
        queryExpression.filterExpression = "picTakenLat < :posLat AND picTakenLat  > :negLat AND picTakenLong < :posLong AND picTakenLong  > :negLong"
        queryExpression.expressionAttributeValues = [":posLat": latBoundPos, ":negLat": latBoundNeg, ":posLong": longBoundPos, ":negLong": longBoundNeg]
//        scanExpression.filterExpression = "picTakenLat > :val"
//        scanExpression.expressionAttributeValues = [":val":latBoundNeg]
//        scanExpression.filterExpression = "picTakenLong < :val"
//        scanExpression.expressionAttributeValues = [":val":longBoundPos]
//        scanExpression.filterExpression = "picTakenLong> :val"
//        scanExpression.expressionAttributeValues = [":val":longBoundNeg]
        
        
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
                completion(result:imagesArray)
                return imagesArray
                
            }
            return imagesArray
        })
            }else{
                print("No zipcodes found")
            }
        })
        }
        return imagesArray
        //        let fetchRequest = NSFetchRequest(entityName: "Entity")
        //        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: false), NSSortDescriptor(key: "upvotes", ascending: false)]
        //        return fetchRequest
    }

    
    func getImagesForGroup(placeName: String, user: User, completion:(result:[Image])->Void)->[Image]{
        
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
            completion(result:imagesArray)
            return imagesArray
        })
            // If the response lastEvaluatedKey has contents, that means there are more results
//        let fetchRequest = NSFetchRequest(entityName: "Entity")
//        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
//        fetchRequest.predicate = NSPredicate(format: "title= %@", placeName)
//        return fetchRequest
        
        return imagesArray
    }
    
    
    func sendGeo() {
        var sendReq : SendGeoRequest = SendGeoRequest()
        var loc :  CLLocationCoordinate2D = CLLocationManager().location!.coordinate
        var requestDictionary = ["action": "query-radius", "request": ["lat": Int(loc.latitude), "lng": Int(loc.longitude), "radiusInMeter": Int(5000)]]
        sendReq.sendRequest(requestDictionary)
//        do{
//
//        var request = NSMutableURLRequest(URL: NSURL(string: AWSElasticBeanstalkEndpoint)!)
//        request.HTTPMethod = "POST"
//            let json = try NSJSONSerialization.dataWithJSONObject(requestDictionary, options: [.PrettyPrinted])
//            request.HTTPBody = json
//        print("Request:\n\(requestDictionary)")
//            let task = NSURLSession.sharedSession().dataTaskWithRequest(request){ data, response, error in
//                if error != nil{
//                    print("Error -> \(error)")
//                    return
//                }
//                
//                do { print("The JSON DATA IS")
//                    print(data)
//                    print(response)
//                    let result = data as! NSMutableData
//                    print(result)
//                    print("Result -> \(result)")
//                    
//                } catch {
//                    print("Error -> \(error)")
//                }
//            }
//        task.resume()
//        }catch{
//            print(error)
//        }
    }
}