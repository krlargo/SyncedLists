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
        usersRef.observeSingleEvent(of: .value, with: { snapshot in
            // Attempt to load addedUser
            var loadingAddedUser = false;
            if let addedByUserID = self.addedByUserID {
                loadingAddedUser = true;
                if(snapshot.hasChild(addedByUserID)) { // Load addedByUserName if addedByUserID exists in USERS
                    let userSnapshot = snapshot.childSnapshot(forPath: addedByUserID);
                    self.addedByUserName = userSnapshot.childSnapshot(forPath: "name").value as! String;
                } else { // Delete addedByUserID if addedByUserID does not exist in USERS
                    self.addedByUserName = "[User Deleted]";
                    self.addedByUserID = nil;
                    self.ref!.child("addedByUserID").removeValue();
                }
                completionHandler();
            } else {
                self.addedByUserName = "[User Deleted]";
                completionHandler();
            }
            
            // Attempt to load completedUser
            var loadingCompletedUser = false;
            if let completedByUserID = self.completedByUserID {
                loadingCompletedUser = true;
                if(snapshot.hasChild(completedByUserID)) { // Load completedByUserName if completedByUserID exists in USERS
                    let userSnapshot = snapshot.childSnapshot(forPath: completedByUserID);
                    self.completedByUserName = userSnapshot.childSnapshot(forPath: "name").value as? String;
                } else { // Delete completedByUserID if completedByUserID does not exist in USERS
                    self.completedByUserName = nil;
                    self.completedByUserID = nil;
                    self.ref!.child("completedByUserID").removeValue();
                }
                completionHandler();
            }
            if(!loadingCompletedUser || !loadingAddedUser) { completionHandler(); }
        });
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
