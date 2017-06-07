//
//  Song+CoreDataProperties.swift
//  
//
//  Created by e.ovsepyan on 05.06.17.
//
//

import Foundation
import CoreData


extension Song {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Song> {
        return NSFetchRequest<Song>(entityName: "Song")
    }

    @NSManaged public var name: String?
    @NSManaged public var path: String?

}
