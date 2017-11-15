//
//  Invite.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/11/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

/*
 When invite is accepted
 - in LISTS move invitedID->listID from invitedIDs to memberIDs
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
    // MARK: - Variables
    let usersRef = Database.database().reference(withPath: "users");
    let listsRef = Database.database().reference(withPath: "lists");

    var senderID: String;
    var senderName: String?
    var recipientID: String;
    var recipientName: String?
    var listID: String;
    var listName: String?
    
    var id: String?
    var ref: DatabaseReference? // Needed for deletion
    
    // Constructor for Firebase-loaded Item
    init(snapshot: DataSnapshot, completionHandler: (() -> Void)?) {
        let snapshotValue = snapshot.value as! [String: AnyObject];
        self.senderID = snapshotValue["senderID"] as! String;
        self.senderName = nil;
        self.recipientID = snapshotValue["recipientID"] as! String;
        self.recipientName = nil;
        self.listID = snapshotValue["listID"] as! String;
        self.listName = nil;
        self.id = snapshot.key;
        self.ref = snapshot.ref;
               
        var observingList = false;
        var observingUser = false;
        
        listsRef.observeSingleEvent(of: .value, with: { snapshot in
           // Check if listID exists in LISTS
            if(snapshot.hasChild(self.listID)) {
                self.listsRef.child(self.listID).child("name")
                    .observeSingleEvent(of: .value, with: { snapshot in
                        observingList = true;
                        self.listName = snapshot.value as? String;

                        // Observe USERS for recipientName
                        self.usersRef.observeSingleEvent(of: .value, with: { snapshot in
                            // If recipientID exists in USERS
                            if(snapshot.hasChild(self.recipientID)) {
                                // Get recipientName from recipientID
                                self.usersRef.child(self.recipientID).child("name")
                                    .observeSingleEvent(of: .value, with: { snapshot in
                                        observingUser = true;
                                        self.recipientName = snapshot.value as? String;

                                        // Observe USERS for senderName
                                        self.usersRef.observeSingleEvent(of: .value, with: { snapshot in
                                            // If senderID exists in USERS
                                            if(snapshot.hasChild(self.senderID)) {
                                                // Get senderName from senderID
                                                self.usersRef.child(self.senderID).child("name")
                                                    .observeSingleEvent(of: .value, with: { snapshot in
                                                        observingUser = true;
                                                        self.senderName = snapshot.value as? String;
                                                    });
                                            } else {
                                                self.senderName = "[Deleted User]";
                                            }
                                        });
                                    });
                            } else { // Recipient doesn't exist; delete entire invite
                                self.delete();
                            }
                        });
                    }); // Observe usersRef
            } else { // List does not exist in LISTS
                self.delete();
            }
            
            defer {
                if let completionHandler = completionHandler {
                    completionHandler();
                }
            }
        }); // Observe listsRef
    }
    
    init(senderID: String, recipientID: String, listID: String) {
        self.senderID = senderID;
        self.senderName = nil;
        self.recipientID = recipientID;
        self.listID = listID;
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
        // Delete from LISTS
        let listRef = self.listsRef.child(listID);
        listRef.child("inviteIDs").child(self.id!).removeValue();
        
        // Delete from USERS
        let recipientUserRef = self.usersRef.child(recipientID);
        recipientUserRef.child("inviteIDs").child(self.id!).removeValue();
        
        // Delete from INVITES
        self.ref!.removeValue();
    }
}
