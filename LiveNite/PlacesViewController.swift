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
    
    func getImagesForGroup(placeName: String)->NSFetchRequest{
        
        let fetchRequest = NSFetchRequest(entityName: "Entity")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "title= %@", placeName)
        return fetchRequest
    }
}