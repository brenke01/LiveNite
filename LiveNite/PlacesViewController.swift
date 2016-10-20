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
    
    var bounds = [CLLocation]()
    var nearbyZipCodes = [String]()
    var data = Data()
    var geoHashArr:[String] = []
    
    func getGroupedImages(_ completion:(_ result:[Image])->Void)->[Image]{
        var groupedArr = [Image]()
        getGroupedImages({(result)->Void in
            let imgArr = result
            
            let sortedArray = (imgArr as NSArray).sortedArray(using: [
                NSSortDescriptor(key: "placeTitle", ascending: false),
                NSSortDescriptor(key: "totalScore", ascending: false)
                ]) as! [Image]
            var found = false
            for img in sortedArray{
                found = false
                for i in 0 ..< groupedArr.count{
                    if (img.placeTitle == groupedArr[i].placeTitle){
                        found = true
                        break
                    }
                }
                if (!found){
                    groupedArr.append(img)
                }
            }

        })
        return groupedArr
        

    }
    
    func getNearbyZipcodes(completion: @escaping (Int)->Void){
        let geoCoder = CLGeocoder()
        let count = 0
      
            geoCoder.reverseGeocodeLocation(self.bounds[count], completionHandler: {(placemarks, error) -> Void in
                if (error != nil){
                    return
                }
                let placemark = placemarks![0]
                let zipcode = placemark.postalCode
                self.nearbyZipCodes.append(zipcode!)
                completion(self.nearbyZipCodes.count)
            })
        
       
    }
    
    
    func getImages(completion:@escaping ([Image])->Void)->[Image]{
        //sendGeo()
        var imagesArray = [Image]()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        let radius : Int = 5
        let latTraveledDeg : Double = (1 / 110.54) * Double(radius)
        let loc :  CLLocationCoordinate2D = CLLocationManager().location!.coordinate
        let  longTraveledDeg : Double = (1 / (111.320 * cos(loc.latitude)))
        let latBoundPos = loc.latitude + latTraveledDeg
        let latBoundNeg = loc.latitude - latTraveledDeg
        let longBoundPos = loc.longitude + longTraveledDeg
        let longBoundNeg = loc.longitude - longTraveledDeg
        self.bounds = [CLLocation(latitude: latBoundPos, longitude: longBoundPos), CLLocation(latitude: latBoundPos, longitude: longBoundNeg), CLLocation(latitude: latBoundNeg, longitude: longBoundPos), CLLocation(latitude: latBoundNeg, longitude: longBoundNeg)]
        var locationManager = CLLocationManager()
        
        for i in self.bounds{
            
            var geo :Geohash = Geohash()
            let l = CLLocationCoordinate2DMake(i.coordinate.latitude, i.coordinate.longitude)
            let s = l.geohash(10)
            self.geoHashArr.append(s)
            
            
        }
        
        
        queryExpression.indexName = "geohash-index"
        queryExpression.hashKeyAttribute = "geohash"
        queryExpression.hashKeyValues = self.geoHashArr[0].substring(to: self.geoHashArr[0].characters.index(self.geoHashArr[0].endIndex, offsetBy: -7))
        
        
       // queryExpression.filterExpression = "picTakenLat < :posLat AND picTakenLat  > :negLat AND picTakenLong < :posLong AND picTakenLong  > :negLong"
        //queryExpression.expressionAttributeValues = [":posLat": latBoundPos, ":negLat": latBoundNeg, ":posLong": longBoundPos, ":negLong": longBoundNeg]
        //        scanExpression.filterExpression = "picTakenLat > :val"
        //        scanExpression.expressionAttributeValues = [":val":latBoundNeg]
        //        scanExpression.filterExpression = "picTakenLong < :val"
        //        scanExpression.expressionAttributeValues = [":val":longBoundPos]
        //        scanExpression.filterExpression = "picTakenLong> :val"
        //        scanExpression.expressionAttributeValues = [":val":longBoundNeg]
        
        
        dynamoDBObjectMapper.query(Image.self, expression: queryExpression).continue({(task: AWSTask) -> AnyObject in
            if (task.error != nil) {
                print("The request failed. Error: [\(task.error)]")
            }
            if (task.exception != nil) {
                print("The request failed. Exception: [\(task.exception)]")
            }
            if (task.result != nil) {
                let output : AWSDynamoDBPaginatedOutput = task.result!
                for image  in output.items {
                    let image : Image = image as! Image
                    imagesArray.append(image)
                }
                completion(imagesArray)
                return imagesArray as AnyObject
                
            }
            return imagesArray as AnyObject
        })

    
        return imagesArray
        //        let fetchRequest = NSFetchRequest(entityName: "Entity")
        //        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: false), NSSortDescriptor(key: "upvotes", ascending: false)]
        //        return fetchRequest
    }

    
    func getImagesForGroup(placeName: String, user: User, completion:@escaping ([Image])->Void)->[Image]{
        let radius : Int = 5
        let latTraveledDeg : Double = (1 / 110.54) * Double(radius)
        let loc :  CLLocationCoordinate2D = CLLocationManager().location!.coordinate
        let  longTraveledDeg : Double = (1 / (111.320 * cos(loc.latitude)))
        let latBoundPos = loc.latitude + latTraveledDeg
        let latBoundNeg = loc.latitude - latTraveledDeg
        let longBoundPos = loc.longitude + longTraveledDeg
        let longBoundNeg = loc.longitude - longTraveledDeg
        self.bounds = [CLLocation(latitude: latBoundPos, longitude: longBoundPos), CLLocation(latitude: latBoundPos, longitude: longBoundNeg), CLLocation(latitude: latBoundNeg, longitude: longBoundPos), CLLocation(latitude: latBoundNeg, longitude: longBoundNeg)]
        var locationManager = CLLocationManager()
        
        for i in self.bounds{
            
            var geo :Geohash = Geohash()
            let l = CLLocationCoordinate2DMake(i.coordinate.latitude, i.coordinate.longitude)
            let s = l.geohash(10)
            self.geoHashArr.append(s)
            
            
        }
        var imagesArray = [Image]()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.indexName = "geohash-index"
        queryExpression.hashKeyAttribute = "geohash"
        queryExpression.hashKeyValues = self.geoHashArr[0].substring(to: self.geoHashArr[0].characters.index(self.geoHashArr[0].endIndex, offsetBy: -7))
        queryExpression.filterExpression = "placeTitle = :placeTitle"
        queryExpression.expressionAttributeValues = [":placeTitle": placeName]
        dynamoDBObjectMapper.query(Image.self, expression: queryExpression).continue({(task: AWSTask) -> AnyObject in
            if (task.error != nil) {
                print("The request failed. Error: [\(task.error)]")
            }
            if (task.exception != nil) {
                print("The request failed. Exception: [\(task.exception)]")
            }
            if (task.result != nil) {
                let output : AWSDynamoDBPaginatedOutput = task.result!
                for image  in output.items {
                    let image : Image = image as! Image
                    imagesArray.append(image)
                }
                completion(imagesArray)
            }
            
            return imagesArray as AnyObject
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
        let loc :  CLLocationCoordinate2D = CLLocationManager().location!.coordinate
        var requestDictionary = ["action": "query-radius", "request": ["lat": Int(loc.latitude), "lng": Int(loc.longitude), "radiusInMeter": Int(5000)]] as [String : Any]
       // sendReq.sendRequest(loc, arg2: 1000)
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
