//
//  User.swift
//  Arrow
//
//  Created by Trevor Sharp on 3/1/16.
//  Copyright © 2016 Trevor Sharp. All rights reserved.
//

import Foundation

class User: NSObject, NSCoding {
    
    // MARK: Properties
    var userID: String?
    var school: School?
    var firstName: String?
    var lastName: String?
    var profilePicture: String?
    
    // MARK: Initializers
    init (userIdentifier: String?, error: NSErrorPointer) {
        // Get user's KiiObject
        userID = userIdentifier
        let table = Table(type: 0)
        if userIdentifier != nil {
            // Search for user object in user table
            let userSearch = table.getObjectsWithKeyValue(["_id": userIdentifier!], limit: 1, error: error)
            if userSearch.count == 1 {
                let user = userSearch[0]
                
                // Get user's school
                let schoolID = user.getObjectForKey("school") as? String
                let schoolTable = Table(type: 1)
                if schoolID != nil {
                    let results = (schoolTable.getObjectsWithKeyValue(["_id": schoolID!], limit: 1, error: error))
                    if results.count != 0 {
                        school = results[0] as? School
                    }
                }
                
                // Get user's firstName, lastName and profilePicture
                firstName = user.getObjectForKey("firstName") as? String
                lastName = user.getObjectForKey("lastName") as? String
                profilePicture = user.getObjectForKey("profilePicture") as? String
            }
        }
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        var error: NSError?
        self.init(userIdentifier: nil, error: &error)
        userID = aDecoder.decodeObjectForKey("userID") as? String
        school = aDecoder.decodeObjectForKey("school") as? School
        firstName = aDecoder.decodeObjectForKey("firstName") as? String
        lastName = aDecoder.decodeObjectForKey("lastName") as? String
        profilePicture = aDecoder.decodeObjectForKey("profilePicture") as? String
    }
    
    // MARK: Function
    func getProfilePicture() -> UIImage? {
        if userID == "dff95c2bd1201e7ca5cf2a83e829068e" {
            return UIImage(named: "Profile-2")
        } else if userID == "576c66a00022-da7b-5e11-386d-08db87fd" {
            return UIImage(named: "Profile-Trevor")
        } else if userID == "afd7ee20-0bbc-11e6-9119-22000a178351" {
                return UIImage(named: "Profile-Anna")
        } else if userID == "b687d050-0bbc-11e6-9f69-22000a69855a" {
            return UIImage(named: "Profile-Philippe")
        } else if userID == "c3cbcf50-0bbc-11e6-9119-22000a178351" {
            return UIImage(named: "Profile-Christian")
        } else {
            return UIImage(named: "Logo-NoCircle")
        }
    }
    
    func getName() -> String {
        return (firstName != nil && lastName != nil) ? (firstName! + " " + lastName!) : ""
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(userID, forKey: "userID")
        aCoder.encodeObject(school, forKey: "school")
        aCoder.encodeObject(firstName, forKey: "firstName")
        aCoder.encodeObject(lastName, forKey: "lastName")
        aCoder.encodeObject(profilePicture, forKey: "profilePicture")
    }
}
