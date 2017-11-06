//
//  List.swift
//  SyncedLists
//
//  Created by Kevin Largo on 10/18/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import FirebaseDatabase
import Foundation

class List {
    var name: String;
    var owner: String;
    
    var ref: DatabaseReference? // Needed for deletion
    var id: String?
    
    var completedCount: Int = 0;
    var itemCount: Int = 0;
    
    // Constructor for Firebase-loaded Item
    init(snapshot: DataSnapshot, completionHandler: @escaping () -> Void) {
        let snapshotValue = snapshot.value as! [String: AnyObject];
        self.name = snapshotValue["name"] as! String;
        self.owner = snapshotValue["owner"] as! String;
        self.ref = snapshot.ref;
        self.id = snapshot.key;
        
        // Get itemCount and completedItemsCount
        let listItemsRef = Database.database().reference(withPath: "items");
        listItemsRef.child(id!).observeSingleEvent(of: .value, with: { snapshot in
            self.itemCount = Int(snapshot.childrenCount);
            
            var completedCount = 0;
            for item in snapshot.children.allObjects as! [DataSnapshot] {
                if(item.hasChild("completedByUserID")) {
                    completedCount += 1;
                }
            }
            self.completedCount = completedCount;
            
            defer { completionHandler(); } // Reload tableview data when this is finished
        });
    }
    
    // Constructor for locally created Item
    init(name: String, owner: String) {
        self.name = name;
        self.owner = owner;
        self.ref = nil;
        self.id = nil;
    }
    
    func toAnyObject() -> Any {
        return [
            "name": self.name,
            "owner": self.owner
        ];
    }
}

