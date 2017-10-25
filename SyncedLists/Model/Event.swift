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
    
    var completedCount: Int = 0;
    var itemCount: Int = 0;
    
    // Constructor for Firebase-loaded Item
    init(snapshot: DataSnapshot) {
        let snapshotValue = snapshot.value as! [String: AnyObject];
        self.name = snapshotValue["name"] as! String;
        self.owner = snapshotValue["owner"] as! String;
        self.ref = snapshot.ref;
        
        let itemsRef = snapshot.ref.child("items");
        
        var completedItemCount = 0;
        var childrenCount = 0;
        itemsRef.observe(.value, with: { (snapshot: DataSnapshot!) in
            childrenCount = Int(snapshot.childrenCount);
            for case let snapshot as DataSnapshot in snapshot.children {
                let item = Item(snapshot: snapshot);
                if(item.isCompleted) {
                    completedItemCount += 1;
                }
            }
        });
        
        self.itemCount = childrenCount;
        self.completedCount = completedItemCount;
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

