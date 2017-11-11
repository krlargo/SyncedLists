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
        self.name = authData.dissplayName!;
        self.email = authData.email!;
        self.id = authData.uid;
    }

    func toAnyObject() -> Any {
        return [
            "name": self.name,
            "email": self.email,
        ];
    }

    func delete() {
        let ref = Database.database().reference();
        let usersRef = ref.child("users");
        let listsRef = ref.child("lists");
        let itemsRef = ref.child("items");
        let emailsRef = ref.child("emails");
        
        let userRef = usersRef.child(self.id);
        
        userRef.child("listIDs").observeSingleEvent(of: .value, with: { snapshot in
            // Iterate through each of the user's lists
            for case let snapshot as DataSnapshot in snapshot.children {
                let listID = snapshot.key;
                listsRef.child(listID).removeValue(); // Delete user's list from LISTS
                itemsRef.child(listID).removeValue(); // Delete user's list's items from ITEMS
            }
            userRef.removeValue(); // Delete from USERS
        });
        
        emailsRef.child(User.emailToID(self.email)).removeValue(); //
    }
    
    class func emailToID(_ email: String) -> String {
        return email.replacingOccurrences(of: ".", with: ",");
    }
    
    class func IDToEmail(_ id: String) -> String {
        return id.replacingOccurrences(of: ",", with: ".");
    }
}
