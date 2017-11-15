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
    
    init(snapshot: DataSnapshot) {
        let snapshotValue = snapshot.value as! [String: AnyObject];
        self.name = snapshotValue["name"] as! String;
        self.email = snapshotValue["email"] as! String;
        self.id = snapshot.key;
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
        let invitesRef = ref.child("invites");
        
        let userRef = usersRef.child(self.id);
        
        // Delete from LISTS
        userRef.child("listIDs").observeSingleEvent(of: .value, with: { snapshot in
            // For each listID
            for case let snapshot as DataSnapshot in snapshot.children {
                let listID = snapshot.key;
                listsRef.child(listID).observeSingleEvent(of: .value, with: { snapshot in
                    let list = List(snapshot: snapshot, completionHandler: nil);
                    if(self.id == list.ownerID) {
                        list.delete();
                    }
                });
            }
        });
        
        // Delete from INVITES
        userRef.child("inviteIDs").observeSingleEvent(of: .value, with: { snapshot in
            // For each inviteID
            for case let snapshot as DataSnapshot in snapshot.children {
                let inviteID = snapshot.key;
                invitesRef.child(inviteID).observeSingleEvent(of: .value, with: { snapshot in
                    let invite = Invite(snapshot: snapshot, completionHandler: nil);
                    invite.delete();
                });
            }
        });

        emailsRef.child(User.emailToID(self.email)).removeValue(); // Delete from EMAILS

        userRef.removeValue(); // Delete from USERS
    }
    
    class func emailToID(_ email: String) -> String {
        return email.replacingOccurrences(of: ".", with: ",");
    }
    
    class func IDToEmail(_ id: String) -> String {
        return id.replacingOccurrences(of: ",", with: ".");
    }
}
