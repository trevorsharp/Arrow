//
//  Post.swift
//  Arrow
//
//  Created by Trevor Sharp on 4/5/16.
//  Copyright © 2016 Trevor Sharp. All rights reserved.
//

import Foundation

class Post: NSObject, NSCoding {
    
    // MARK: Properties
    var user: User // database: "_owner"
    var text: String // database: "text"
    var date: Double // database: "_created"
    var classID: String // database: "class"
    var numberOfLikes: Int
    var numberOfComments: Int
    var liked: Bool
    var identifier: String? //database: "_id", created by database
    
    // MARK: Initializers
    init(_: Int) {
        var error: NSError?
        user = User(userIdentifier: nil, error: &error)
        text = ""
        date = 0
        classID = ""
        numberOfComments = 0
        numberOfLikes = 0
        liked = false
    }
    
    init(postText: String, classIdentifier: String) {
        user = CurrentUser()
        text = postText
        date = NSDate().timeIntervalSince1970 as Double
        classID = classIdentifier
        numberOfComments = 0
        numberOfLikes = 0
        liked = false
    }
    
    init(kiiObject: KiiObject) {
        text = kiiObject.getObjectForKey("text") as! String
        date = Double(kiiObject.getObjectForKey("created") as! String)! // TESTING
        identifier = kiiObject.getObjectForKey("_id") as? String
        classID = kiiObject.getObjectForKey("class") as! String
        var error: NSError?
        if let userID = kiiObject.getObjectForKey("owner") as? String { // TESTING
            let table = Table(type: 0)
            let results = table.getObjectsWithKeyValue(["_id": userID], limit: 1, error: &error)
            if results.count != 0 {
                let userID = (results[0] as! KiiObject).getObjectForKey("_id") as! String
                user = User(userIdentifier: userID, error: &error)
            } else {
                user = User(userIdentifier: nil, error: &error)
            }
        } else {
            user = User(userIdentifier: nil, error: &error)
        }
        if identifier != nil {
            var table = Table(type: 4)
            numberOfComments = table.getObjectsWithKeyValue(["post": identifier!], limit: 0, error: &error).count
            table = Table(type: 5)
            let results = table.getObjectsWithKeyValue(["post": identifier!], limit: 0, error: &error) as! [Like]
            numberOfLikes = results.count
            liked = false
            if let currentUserID  = CurrentUser().userID {
                for like in results {
                    if like.userID == currentUserID {
                        liked = true
                    }
                }
            }
        } else {
            numberOfLikes = 0
            numberOfComments = 0
            liked = false
        }
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        self.init(0)
        user = aDecoder.decodeObjectForKey("user") as! User
        text = aDecoder.decodeObjectForKey("text") as! String
        date = aDecoder.decodeObjectForKey("date") as! Double
        classID = aDecoder.decodeObjectForKey("classID") as! String
        numberOfLikes = aDecoder.decodeIntegerForKey("numberOfLikes")
        numberOfComments = aDecoder.decodeIntegerForKey("numberOfComments")
        liked = aDecoder.decodeObjectForKey("liked") as! Bool
        identifier = aDecoder.decodeObjectForKey("id") as? String
    }
    
    // MARK: Functions
    func addToDatabase(error: NSErrorPointer) {
        let table = Table(type: 3)
        table.createObjectWithStringKeys(["text": text, "class": classID], error: error)
    }
    
    func getDate() -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeZone = NSTimeZone()
        let returnDate = dateFormatter.stringFromDate(NSDate(timeIntervalSince1970: date))
        return returnDate.substringToIndex(returnDate.startIndex.advancedBy((returnDate.characters.count)-6))
    }
    
    func like(error: NSErrorPointer) {
        if let postID = identifier {
            if let userID = CurrentUser().userID {
                let table = Table(type: 5)
                if table.getObjectsWithKeyValue(["post": postID, "user": userID], limit: 1, error: error).count == 0 {
                    let like = Like(user: userID, post: postID)
                    like.addToDatabase(error)
                }
            }
        }
    }
    
    func refresh(error: NSErrorPointer) {
        if identifier != nil {
            var table = Table(type: 4)
            numberOfComments = table.getObjectsWithKeyValue(["post": identifier!], limit: 0, error: error).count
            table = Table(type: 5)
            numberOfLikes = table.getObjectsWithKeyValue(["post": identifier!], limit: 0, error: error).count
        }
    }
    
    func removeSelf(error: NSErrorPointer) {
        var table = Table(type: 3)
        if let id = identifier {
            table.deleteObjectWithStringKeys(["_id": id], error: error)
            table = Table(type: 4)
            table.deleteObjectWithStringKeys(["post": id], error: error)
            table = Table(type: 5)
            table.deleteObjectWithStringKeys(["post": id], error: error)
        }
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(user, forKey: "user")
        aCoder.encodeObject(text, forKey: "text")
        aCoder.encodeObject(date, forKey: "date")
        aCoder.encodeObject(classID, forKey: "classID")
        aCoder.encodeInteger(numberOfLikes, forKey: "numberOfLikes")
        aCoder.encodeInteger(numberOfComments, forKey: "numberOfComments")
        aCoder.encodeObject(liked, forKey: "liked")
        aCoder.encodeObject(identifier, forKey: "id")
    }
}