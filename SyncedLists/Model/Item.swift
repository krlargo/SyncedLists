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
    var addedByUser: String;
    var completedByUser: String?
    var addedByUserName: String!;
    var completedByUserName: String?
    var ref: DatabaseReference? // Needed for deletion
    
    // Constructor for Firebase-loaded Item
    init(snapshot: DataSnapshot, completionHandler: @escaping () -> Void) {
        let snapshotValue = snapshot.value as! [String: AnyObject];
        self.name = snapshotValue["name"] as! String;
        self.addedByUser = snapshotValue["addedByUser"] as! String;
        self.completedByUser = snapshotValue["completedByUser"] as? String;
        self.ref = snapshot.ref;

        // Nest observers so completionHandler only needs to be called once
        // Observe addedByUserName
        Database.database().reference(withPath: "users")
            .child(addedByUser).child("name")
            .observeSingleEvent(of: .value, with: { snapshot in
                self.addedByUserName = snapshot.value as! String;
                // If available, observe completedByUserName
                if let completedByUser = self.completedByUser {
                    Database.database().reference(withPath: "users")
                        .child(completedByUser).child("name")
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
        self.addedByUser = user.id;
        self.addedByUserName = user.name;
        self.completedByUser = nil;
        self.completedByUserName = nil;
        self.ref = nil;
    }
    
    func toAnyObject() -> Any {
        return [
            "name": self.name,
            "addedByUser": self.addedByUser,
            "completedByUser": self.completedByUser
        ];
    }
}
