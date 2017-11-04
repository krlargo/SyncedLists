//
//  Item.swift
//  SyncedLists
//
//  Created by Kevin Largo on 10/17/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import FirebaseDatabase
import Foundation

struct Item {
    var name: String;
    var addedByUser: String;
    var completedBy: String?;
    var ref: DatabaseReference? // Needed for deletion
    
    /*var addedByUserName: String {
        return Database.database().reference(withPath: "users/\(addedByUser)").value(forKey: "name") as! String;
    }
    var completedByUserName: String? {
        return Database.database().reference(withPath: "users/\(completedBy)").value(forKey: "name") as? String;
    }
    
    func getUserName(from email: String) -> String {
        return
    }*/
    
    // Constructor for Firebase-loaded Item
    init(snapshot: DataSnapshot) {
        let snapshotValue = snapshot.value as! [String: AnyObject];
        name = snapshotValue["name"] as! String;
        addedByUser = snapshotValue["addedByUser"] as! String;
        completedBy = snapshotValue["completedBy"] as? String
        self.ref = snapshot.ref;
    }
    
    // Constructor for locally created Item
    init(name: String, addedByUser: String) {
        self.name = name;
        self.addedByUser = addedByUser;
        self.completedBy = nil;
        self.ref = nil;
    }
    
    func toAnyObject() -> Any {
        return [
            "name": self.name,
            "addedByUser": self.addedByUser,
            "completedBy": self.completedBy
        ];
    }
}
