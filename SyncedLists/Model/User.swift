//
//  User.swift
//  SyncedLists
//
//  Created by Kevin Largo on 10/17/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import FirebaseDatabase
import FirebaseAuth
import Foundation

class User {
    var name: String;
    var email: String;
    var id: String;
    
    // Constructor for Firebase-loaded User
    init(authData: FirebaseAuth.User) {
        self.name = authData.displayName!;
        self.email = authData.email!;
        self.id = authData.uid;
    }

    func toAnyObject() -> Any {
        return [
            "name": self.name,
            "email": self.email,
        ];
    }

    func deleteCascadingData() {
        let ref = Database.database().reference();
        let usersRef = ref.child("users");
        let listsRef = ref.child("lists");
        let itemsRef = ref.child("items");
        
        let userRef = usersRef.child(self.id);
        
        userRef.child("listIDs").observeSingleEvent(of: .value, with: { snapshot in
            // Iterate through each of the user's lists
            for case let snapshot as DataSnapshot in snapshot.children {
                let listID = snapshot.key;
                listsRef.child(listID).removeValue(); // Delete list with listID
                itemsRef.child(listID).removeValue(); // Delete items with listID
            }
            userRef.removeValue(); // Delete user when finished
        });
    }
}
