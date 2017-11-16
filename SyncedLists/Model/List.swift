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
    var ownerID: String;
    
    var id: String?
    var ref: DatabaseReference? // Needed for deletion
    
    var completedCount: Int = 0;
    var itemCount: Int = 0;
    
    init(snapshot: DataSnapshot, completionHandler: (() -> Void)?) {
        let snapshotValue = snapshot.value as! [String: AnyObject];
        self.name = snapshotValue["name"] as! String;
        self.ownerID = snapshotValue["ownerID"] as! String;
        self.id = snapshot.key;
        self.ref = snapshot.ref;
        
        // Get itemCount and completedItemsCount
        let listItemsRef = Database.database().reference(withPath: "items");
        listItemsRef.child(id!).observe(.value, with: { snapshot in
            self.itemCount = Int(snapshot.childrenCount);
            
            var completedCount = 0;
            for item in snapshot.children.allObjects as! [DataSnapshot] {
                if(item.hasChild("completedByUserID")) {
                    completedCount += 1;
                }
            }
            self.completedCount = completedCount;
            
            if let completionHandler = completionHandler {
                completionHandler();
            }
        });
    }
    
    // Constructor for locally created Item
    init(name: String, ownerID: String) {
        self.name = name;
        self.ownerID = ownerID;
        self.ref = nil;
        self.id = nil;
    }
    
    func toAnyObject() -> Any {
        return [
            "name": self.name,
            "ownerID": self.ownerID
        ];
    }
    
    func delete() {
        let usersRef = Database.database().reference(withPath: "users");
        let itemsRef = Database.database().reference(withPath: "items");
        let invitesRef = Database.database().reference(withPath: "invites");
        
        // Delete from ITEMS
        itemsRef.child(self.id!).removeValue();
        
        // Delete from USERS
        self.ref!.child("memberIDs").observeSingleEvent(of: .value, with: { snapshot in
            // For each memberID
            for case let snapshot as DataSnapshot in snapshot.children {
                let userID = snapshot.key;
                usersRef.child(userID).child(self.id!).removeValue();
            }
        });
        
        // Delete from INVITES
        self.ref!.child("inviteIDs").observeSingleEvent(of: .value, with: { snapshot in
            // For each inviteID, delete invite
            for case let snapshot as DataSnapshot in snapshot.children {
                let inviteID = snapshot.key;
                invitesRef.child(inviteID).observeSingleEvent(of: .value, with: { snapshot in
                    let invite = Invite(snapshot: snapshot, completionHandler: nil);
                    invite.delete();
                });
            }
        });
        
        // Delete from LISTS
        self.ref!.removeValue();
    }
}

