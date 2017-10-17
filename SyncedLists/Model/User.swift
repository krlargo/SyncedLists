//
//  User.swift
//  SyncedLists
//
//  Created by Kevin Largo on 10/17/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import Firebase
import Foundation

struct User {
    var uid: String;
    var email: String;
    
    // Constructor for Firebase-loaded User
    init(authData: User) {
        self.uid = authData.uid;
        self.email = authData.email;
    }
    
    // Constructor for locally created User
    init(uid: String, email: String) {
        self.uid = uid;
        self.email = email;
    }
}
