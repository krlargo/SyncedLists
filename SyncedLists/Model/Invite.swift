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

    var senderID: String?;
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
        self.senderID = snapshotValue["senderID"] as? String;
        self.senderName = nil;
        self.recipientID = snapshotValue["recipientID"] as! String;
        self.recipientName = nil;
        self.listID = snapshotValue["listID"] as! String;
        self.listName = nil;
        self.id = snapshot.key;
        self.ref = snapshot.ref;
        
        // Observe LISTS for listName
        listsRef.observeSingleEvent(of: .value, with: { snapshot in
            if(snapshot.hasChild(self.listID)) { // Load listName if listID exists in LISTS
                let listSnapshot = snapshot.childSnapshot(forPath: self.listID);
                self.listName = listSnapshot.childSnapshot(forPath: "name").value as? String;
                
                self.loadSenderName(completionHandler: completionHandler);
                self.loadRecipientName(completionHandler: completionHandler);
            } else { // Delete invite if listID does not exist in LISTS
                self.delete();
            }
        });
    }
    
    func loadRecipientName(completionHandler: (() -> Void)?) {
        // Observe USERS for recipientName
        self.usersRef.observe(.value, with: { snapshot in
            if(snapshot.hasChild(self.recipientID)) { // Load recipientName if recipientID exists in USERS
                let userSnapshot = snapshot.childSnapshot(forPath: self.recipientID);
                self.recipientName = userSnapshot.childSnapshot(forPath: "name").value as? String;
                if let completionHandler = completionHandler {
                    completionHandler();
                }
            } else { // Delete invite if recipientID does not exist in USERS
                self.delete();
            }
        });
    }
    
    func loadSenderName(completionHandler: (() -> Void)?) {
        // Observe USERS for senderName
        self.usersRef.observe(.value, with: { snapshot in
            if let senderID = self.senderID {
                if(snapshot.hasChild(senderID)) { // Load senderName if senderID exists in USERS
                    let userSnapshot = snapshot.childSnapshot(forPath: senderID);
                    self.senderName = userSnapshot.childSnapshot(forPath: "name").value as? String;
                    if let completionHandler = completionHandler {
                        completionHandler();
                    }
                } else {
                    self.senderName = "[Deleted User]";
                    self.ref!.child("senderID").removeValue();
                    if let completionHandler = completionHandler {
                        completionHandler();
                    }
                }
            } else {
                if let completionHandler = completionHandler {
                    completionHandler();
                }
            }
       });
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
