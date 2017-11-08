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
    
    // Firebase userID uses "," instead of "."
    var id: String {
        return User.emailToID(email);
    }
    
    // Constructor for Firebase-loaded User
    init(authData: FirebaseAuth.User) {
        self.name = authData.displayName!;
        self.email = authData.email!;
    }
    
    // Constructor for locally created User
    init(name: String, email: String) {
        self.name = name;
        self.email = email;
    }

    func toAnyObject() -> Any {
        return [
            "name": self.name,
            "email": self.email,
        ];
    }
    
    // Type methods
    class func emailToID(_ emailStr: String) -> String {
        return emailStr.replacingOccurrences(of: ".", with: ",");
    }
    
    class func nameOfUser(withEmail emailStr: String) -> String {
        var name: String = "";
        let userID = User.emailToID(emailStr);
        
        Database.database().reference(withPath: "users")
            .child(userID).child("name")
            .observe(.value, with: { snapshot in
                if let observedName = snapshot.value as? String {
                    name = observedName;
                }
            });
        return name;
    }
}
