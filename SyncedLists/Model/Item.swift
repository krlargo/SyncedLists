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
    var ref: DatabaseReference? // Needed for deletion
    
    // Constructor for Firebase-loaded Item
    init(snapshot: DataSnapshot) {
        let snapshotValue = snapshot.value as! [String: AnyObject]
        name = snapshotValue["name"] as! String
        addedByUser = snapshotValue["addedByUser"] as! String
        self.ref = snapshot.ref;
    }
    
    // Constructor for locally created Item
    init(name: String, addedByUser: String) {
        self.name = name;
        self.addedByUser = addedByUser;
        self.ref = nil;
    }
    
    func toAnyObject() -> Any {
        return [
            "name": name,
            "addedByUser": addedByUser
        ];
    }
}
