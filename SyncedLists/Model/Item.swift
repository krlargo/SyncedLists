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
    var addedByUserID: String;
    var addedByUserName: String!;
    var completedByUserID: String?
    var completedByUserName: String?
    var ref: DatabaseReference? // Needed for deletion
    
    // Constructor for Firebase-loaded Item
    init(snapshot: DataSnapshot, completionHandler: @escaping () -> Void) {
        let snapshotValue = snapshot.value as! [String: AnyObject];
        self.name = snapshotValue["name"] as! String;
        self.addedByUserID = snapshotValue["addedByUserID"] as! String;
        self.completedByUserID = snapshotValue["completedByUserID"] as? String
        self.ref = snapshot.ref;

        // Nest observers so completionHandler only needs to be called once
        // Observe addedByUserName
        Database.database().reference(withPath: "users")
            .child(User.emailToID(addedByUserID)).child("name")
            .observeSingleEvent(of: .value, with: { snapshot in
                self.addedByUserName = snapshot.value as! String;
                // If available, observe completedByUserName
                if let completedByUserID = self.completedByUserID {
                    Database.database().reference(withPath: "users")
                        .child(User.emailToID(completedByUserID)).child("name")
                        .observeSingleEvent(of: .value, with: { snapshot in
                            self.completedByUserName = snapshot.value as? String;
                            completionHandler();
                        });
                }
                completionHandler();
            });
    }
    
    // Constructor for locally created Item
    init(name: String, addedBy user: User) {
        self.name = name;
        self.addedByUserID = user.id;
        //self.addedByUserName = user.name;
        self.completedByUserID = nil;
        self.ref = nil;
    }
    
    func toAnyObject() -> Any {
        return [
            "name": self.name,
            "addedByUserID": self.addedByUserID,
            "completedByUserID": self.completedByUserID
        ];
    }
}
