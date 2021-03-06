//
//  Invite.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/11/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import FirebaseDatabase
import Foundation

class Invite {
    // MARK: - Variables
    let usersRef = Database.database().reference(withPath: "users");
    let listsRef = Database.database().reference(withPath: "lists");

    var senderID: String?
    var senderName: String?
    var senderUsername: String?
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
        self.senderUsername = nil;
        self.recipientID = snapshotValue["recipientID"] as! String;
        self.recipientName = nil;
        self.listID = snapshotValue["listID"] as! String;
        self.listName = nil;
        self.id = snapshot.key;
        self.ref = snapshot.ref;
        
        // Observe LISTS for listName
        self.listsRef.child(self.listID).observeSingleEvent(of: .value) { snapshot in
            if(!(snapshot.value is NSNull)) { // Load listName if listID exists in LISTS
                let snapshotValue = snapshot.value as! [String: Any];
                self.listName = snapshotValue["name"] as? String;
                self.loadSenderNames(completionHandler: completionHandler);
                self.loadRecipientName(completionHandler: completionHandler);
            } else { // Delete invite if listID does not exist in LISTS
                self.delete();
            }
        };
    }
    
    func loadRecipientName(completionHandler: (() -> Void)?) {
        // Observe USERS for recipientName
        self.usersRef.child(self.recipientID).observeSingleEvent(of: .value) { snapshot in
            if(!(snapshot.value is NSNull)) { // Load recipientName if recipientID exists in USERS
                let snapshotValue = snapshot.value as! [String: Any];
                self.recipientName = snapshotValue["name"] as? String;
                if let completionHandler = completionHandler {
                    completionHandler();
                }
            } else { // Delete invite if recipientID does not exist in USERS
                self.delete();
            }
        }
    }
    
    func loadSenderNames(completionHandler: (() -> Void)?) {
        // Observe USERS for senderName
        if let senderID = self.senderID { // Load senderName if senderID exists in USERS
            self.usersRef.child(senderID).observeSingleEvent(of: .value) { snapshot in
                if(!(snapshot.value is NSNull)) {
                    let snapshotValue = snapshot.value as! [String: Any];
                    self.senderName = snapshotValue["name"] as? String;
                    self.senderUsername = snapshotValue["username"] as? String;
                    if let completionHandler = completionHandler {
                        completionHandler();
                    }
                } else {
                    self.senderName = "[Deleted User]";
                    self.senderUsername = "[Deleted User]";
                    self.ref!.child("senderID").removeValue();
                    if let completionHandler = completionHandler {
                        completionHandler();
                    }
                }
            }
        } else {
            self.senderName = "[Deleted User]";
            if let completionHandler = completionHandler {
                completionHandler();
            }
        }
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
