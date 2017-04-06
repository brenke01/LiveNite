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
import CoreLocation


class PlacesViewController{
    
    var bounds = [CLLocation]()
    var nearbyZipCodes = [String]()
    var data = Data()
    var geoHashArr:[String] = []
    var userLocation = CLLocationCoordinate2D()
    var locationUpdated = false
    
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations[0].coordinate
        print("\(userLocation.latitude) Degrees Latitude, \(userLocation.longitude) Degrees Longitude")
        locationUpdated = true
    }
    
    
    func getImages(user: User, completion:@escaping ([Image])->Void)->[Image]{
        //
        //find approx images and post process ones that have coordinates that are a distance away.
        //
        //sendGeo()
        var locationManager = CLLocationManager()
        var imagesArray = [Image]()
        let dynamoDBObjectMapper: AWSDynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        let scanExpression = AWSDynamoDBScanExpression()
        
        let radius : Int = 5
        let latTraveledDeg : Double = (1 / 110.54) * (Double(user.distance) * 0.621371)
        
        if #available(iOS 8.0, *) {
            locationManager.requestWhenInUseAuthorization()
        } else {
            // Fallback on earlier versions
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.stopUpdatingLocation()
        let currentLoc = locationManager.location
        let loc :  CLLocationCoordinate2D = locationManager.location!.coordinate
        let  longTraveledDeg : Double = (1 / (111.320 * cos(loc.latitude))) * (Double(user.distance) * 0.621371)
        let latBoundPos = loc.latitude + latTraveledDeg
        let latBoundNeg = loc.latitude - latTraveledDeg
        let longBoundPos = loc.longitude + longTraveledDeg
        let longBoundNeg = loc.longitude - longTraveledDeg
        let latBoundPosHalf = loc.latitude + (latTraveledDeg * 0.5)
        let latBoundNegHalf = loc.latitude - (latTraveledDeg * 0.5)
        let longBoundPosHalf = loc.longitude + (longTraveledDeg * 0.5)
        let longBoundNegHalf = loc.longitude - (longTraveledDeg * 0.5)
        self.bounds = [CLLocation(latitude: latBoundPos, longitude: longBoundPos), CLLocation(latitude: latBoundPos, longitude: longBoundNeg), CLLocation(latitude: latBoundNeg, longitude: longBoundPos), CLLocation(latitude: latBoundNeg, longitude: longBoundNeg), CLLocation(latitude: latBoundPosHalf, longitude: longBoundPosHalf), CLLocation(latitude: latBoundPosHalf, longitude: longBoundNegHalf), CLLocation(latitude: latBoundNegHalf, longitude: longBoundPosHalf), CLLocation(latitude: latBoundNegHalf, longitude: longBoundNegHalf)]
        
        
        for i in self.bounds{
            
            var geo :Geohash = Geohash()
            let l = CLLocationCoordinate2DMake(i.coordinate.latitude, i.coordinate.longitude)
            let s = l.geohash(10)
            self.geoHashArr.append(s)
            
            
        }
        
        scanExpression.filterExpression = "geohash = :val1 or geohash = :val2"
        scanExpression.expressionAttributeValues = [":val1": self.geoHashArr[3].substring(to: self.geoHashArr[3].characters.index(self.geoHashArr[3].endIndex, offsetBy: -7)), ":val2": self.geoHashArr[0].substring(to: self.geoHashArr[0].characters.index(self.geoHashArr[0].endIndex, offsetBy: -7))]
        //queryExpression.indexName = "geohash-index"
        //queryExpression.hashKeyAttribute = "geohash"
        //queryExpression.hashKeyValues = self.geoHashArr[3].substring(to: self.geoHashArr[3].characters.index(self.geoHashArr[3].endIndex, offsetBy: -6))
        
        
       // queryExpression.filterExpression = "picTakenLat < :posLat AND picTakenLat  > :negLat AND picTakenLong < :posLong AND picTakenLong  > :negLong"
        //queryExpression.expressionAttributeValues = [":posLat": latBoundPos, ":negLat": latBoundNeg, ":posLong": longBoundPos, ":negLong": longBoundNeg]
        //        scanExpression.filterExpression = "picTakenLat > :val"
        //        scanExpression.expressionAttributeValues = [":val":latBoundNeg]
        //        scanExpression.filterExpression = "picTakenLong < :val"
        //        scanExpression.expressionAttributeValues = [":val":longBoundPos]
        //        scanExpression.filterExpression = "picTakenLong> :val"
        //        scanExpression.expressionAttributeValues = [":val":longBoundNeg]
        
        
        dynamoDBObjectMapper.scan(Image.self, expression: scanExpression).continue({(task: AWSTask) -> AnyObject in
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
                    var imgLoc = CLLocation(latitude: Double(image.placeLat), longitude: Double(image.placeLong))
                    var distance = imgLoc.distance(from: currentLoc!)
                    if ((distance * 0.000621371) <= Double(user.distance)){
                        imagesArray.append(image)

                    }
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
