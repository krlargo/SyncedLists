//
//  Item.swift
//  SyncedLists
//
//  Created by Kevin Largo on 10/17/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import FirebaseDatabase
import Foundation

class Item {
    var name: String;
    var addedByUserID: String?
    var completedByUserID: String?
    var addedByUserName: String!
    var completedByUserName: String?
    var ref: DatabaseReference? // Needed for deletion
    
    // Constructor for Firebase-loaded Item
    init(snapshot: DataSnapshot, completionHandler: @escaping () -> Void) {
        let snapshotValue = snapshot.value as! [String: AnyObject];
        self.name = snapshotValue["name"] as! String;
        self.addedByUserID = snapshotValue["addedByUserID"] as? String;
        self.completedByUserID = snapshotValue["completedByUserID"] as? String;
        self.ref = snapshot.ref;

        // Nest observers so completionHandler only needs to be called once
        // Observe addedByUserName
        let usersRef = Database.database().reference(withPath: "users");
        //,,,
        // Attempt to load addedBy-User
        if let addedByUserID = self.addedByUserID {
            usersRef.child(addedByUserID).observeSingleEvent(of: .value) { snapshot in
                if(!(snapshot.value is NSNull)) {
                    let snapshotValue = snapshot.value as! [String: Any];
                    self.addedByUserName = snapshotValue["name"] as! String;
                } else {
                    self.addedByUserName = "[User Deleted]";
                    self.addedByUserID = nil;
                    self.ref!.child("addedByUserID").removeValue();
                }
                completionHandler();
            };
        } else {
            self.addedByUserName = "[User Deleted]";
            completionHandler();
        }
        // Attempt to load completedBy-User
        if let completedByUserID = self.completedByUserID {
            usersRef.child(completedByUserID).observeSingleEvent(of: .value) { snapshot in
                if(!(snapshot.value is NSNull)) {
                    let snapshotValue = snapshot.value as! [String: Any];
                    self.completedByUserName = snapshotValue["name"] as? String;
                } else {
                    self.completedByUserName = nil;
                    self.completedByUserID = nil;
                    self.ref!.child("completedByUserID").removeValue();
                }
                completionHandler();
            };
        } else {
            self.completedByUserName = nil;
            completionHandler();
        }
    }
    
    // Constructor for locally created Item
    init(name: String, addedBy user: User) {
        self.name = name;
        self.addedByUserID = user.id;
        self.addedByUserName = user.name;
        self.completedByUserID = nil;
        self.completedByUserName = nil;
        self.ref = nil;
    }
    
    func toAnyObject() -> Any {
        return [
            "name": self.name,
            "addedByUserID": self.addedByUserID,
            "completedByUserID": self.completedByUserID
        ];
    }
    
    func delete() {
        // No need to delete from LISTS becauase lists
        // simply references items by listID
        
        // Delete from ITEMS
        self.ref?.removeValue();
    }
}
