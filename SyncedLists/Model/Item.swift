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
    var isCompleted: Bool;
    var completedBy: String?;
    var ref: DatabaseReference? // Needed for deletion
    
    // Constructor for Firebase-loaded Item
    init(snapshot: DataSnapshot) {
        let snapshotValue = snapshot.value as! [String: AnyObject];
        name = snapshotValue["name"] as! String;
        addedByUser = snapshotValue["addedByUser"] as! String;
        isCompleted = snapshotValue["isCompleted"] as! Bool;
        completedBy = snapshotValue["completedBy"] as? String
        self.ref = snapshot.ref;
    }
    
    // Constructor for locally created Item
    init(name: String, addedByUser: String) {
        self.name = name;
        self.addedByUser = addedByUser;
        self.isCompleted = false;
        self.completedBy = nil;
        self.ref = nil;
    }
    
    func toAnyObject() -> Any {
        return [
            "name": self.name,
            "addedByUser": self.addedByUser,
            "isCompleted": self.isCompleted,
            "completedBy": self.completedBy
        ];
    }
}
