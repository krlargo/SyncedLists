//
//  Invite.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/11/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

/*
 When invite is accepted
 - in LISTS move invitedID from invitedIDs to memberIDs
 - delete inviteID from recipientUSER's inviteIDs
 - delete invite from INVITES
 
 When invite is declined
 - in LISTS remove invitedID from invitedIDs
 - delete inviteID from recipientUSER's inviteIDs
 - delete invite from INVITES
 */

import FirebaseDatabase
import Foundation

class Invite {
    var senderID: String;
    var senderName: String?
    var recipientID: String;
    var listID: String;
    var listName: String?
    
    var id: String?
    var ref: DatabaseReference? // Needed for deletion
    
    // Constructor for Firebase-loaded Item
    init(snapshot: DataSnapshot, completionHandler: @escaping () -> Void) {
        let snapshotValue = snapshot.value as! [String: AnyObject];
        self.senderID = snapshotValue["senderID"] as! String;
        self.senderName = nil;
        self.recipientID = snapshotValue["recipientID"] as! String;
        self.listID = snapshotValue["listID"] as! String;
        self.listName = nil;
        self.id = snapshot.key;
        self.ref = snapshot.ref;
        
        let usersRef = Database.database().reference(withPath: "users");
        let listsRef = Database.database().reference(withPath: "lists");
       
        var observingList = false;
        var observingUser = false;
        
        listsRef.observeSingleEvent(of: .value, with: { snapshot in
           // Check if listID exists in LISTS
            if(snapshot.hasChild(self.listID)) {
                listsRef.child(self.listID).child("name")
                    .observeSingleEvent(of: .value, with: { snapshot in
                        observingList = true;
                        self.listName = snapshot.value as? String;

                        // Check if userID exists in USERS
                        usersRef.observeSingleEvent(of: .value, with: { snapshot in
                            if(snapshot.hasChild(self.senderID)) {
                                usersRef.child(self.senderID).child("name")
                                    .observeSingleEvent(of: .value, with: { snapshot in
                                        observingUser = true;
                                        self.senderName = snapshot.value as? String;
                                    });
                            } else {
                                self.senderName = "[Deleted User]";
                                completionHandler();
                            }
                        });
                    }); // Observe usersRef
            } else { // List does not exist in LISTS
                self.delete();
                completionHandler();
            }
            
            if(!observingList && !observingUser) {
                completionHandler();
            }
        }); // Observe listsRef
    }
    
    init(senderID: String, recipientID: String, listID: String) {
        self.senderID = senderID;
        self.senderName = nil;
        self.recipientID = recipientID;
        self.listID = list;
        self.listName = nil;
        self.ref = nil;
    }
    
    func toAnyObject() -> Any {
        return [
            "senderID": self.senderID,
            "recipientID": self.recipientID,
            "listID": self.listID
        ];
    }
    
    func delete() {
        self.ref!.removeValue();
    }
}
