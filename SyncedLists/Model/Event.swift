//
//  Event.swift
//  SyncedLists
//
//  Created by Kevin Largo on 10/18/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import FirebaseDatabase
import Foundation

struct Event {
    var name: String;
    var owner: String;
    var ref: DatabaseReference? // Needed for deletion
    
    // Constructor for Firebase-loaded Item
    init(snapshot: DataSnapshot) {
        let snapshotValue = snapshot.value as! [String: AnyObject];
        name = snapshotValue["name"] as! String;
        owner = snapshotValue["owner"] as! String;
        self.ref = snapshot.ref;
    }
    
    // Constructor for locally created Item
    init(name: String, owner: String) {
        self.name = name;
        self.owner = owner;
        self.ref = nil;
    }
    
    func toAnyObject() -> Any {
        return [
            "name": self.name,
            "owner": self.owner
        ];
    }
}

