//
//  MembersTableViewController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/9/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import UIKit

class MembersTableViewController: UITableViewController {
    // MARK: - Variables
    var usersRef = Database.database().reference(withPath: "users");
    var usernamesRef = Database.database().reference(withPath: "usernames");
    var emailsRef = Database.database().reference(withPath: "emails");
    var invitesRef = Database.database().reference(withPath: "invites");
    var listsRef = Database.database().reference(withPath: "lists");
    
    var listRef: DatabaseReference!
    
    var currentUsername: String!
    var listID: String!
    var listOwnerName: String!
    
    var joinedUsers: [User] = [];
    var invites: [Invite] = [];
    
    // MARK: - IBActions
    @IBAction func addMember(_ sender: Any) {
        let alert = UIAlertController(title: "Invite Member", message: "", preferredStyle: .alert);
        
        let saveAction = UIAlertAction(title: "Invite", style: .default) { _ in
            guard let textField = alert.textFields?.first,
                let invitedUser = textField.text?.lowercased() else { return; }
            
            // Email validation
            if(invitedUser == Auth.auth().currentUser!.email! ||
                invitedUser == self.currentUsername) {
                Utility.presentErrorAlert(message: "You cannot invite yourself.", from: self);
                return;
            }
            
            Utility.showActivityIndicator(in: self.navigationController!.view!);
            
            // Save invite
            let senderID = Auth.auth().currentUser!.uid;
            var loadedID: String?
            
            // Check that recipient exists
            if(invitedUser.isAlphanumeric) { // Check that username exists in database
                self.usernamesRef.child(invitedUser).observeSingleEvent(of: .value) { snapshot in
                    if(!(snapshot.value is NSNull)) {
                        loadedID = snapshot.value as? String;
                        inviteUser(with: loadedID);
                    }
                }
            } else { // Check that email exists in database
                let recipientEmailAsID = User.emailToID(invitedUser);
                self.emailsRef.child(recipientEmailAsID).observeSingleEvent(of: .value) { snapshot in
                    if(!(snapshot.value is NSNull)) {
                        loadedID = snapshot.value as? String;
                        inviteUser(with: loadedID);
                    }
                }
            }
            
            func inviteUser(with loadedID: String?) {
                guard let recipientID = loadedID else {
                    Utility.presentErrorAlert(message: "\(invitedUser.contains("@") ? "Email" : "Username") \"\(invitedUser)\" does not exist.", from: self);
                    return;
                }
                
                let invite = Invite(senderID: senderID, recipientID: recipientID, listID: self.listID)
                
                self.listRef.child("inviteIDs").observeSingleEvent(of: .value) { snapshot in
                    // If list's inviteIDs already contains email
                    if(snapshot.hasChild(recipientID)) {
                        Utility.presentErrorAlert(message: "\(invitedUser.contains("@") ? "Email" : "Username") \"\(invitedUser)\" has already been invited.", from: self)
                    } else { // Invite user
                        // Add to INVITES
                        let inviteRef = self.invitesRef.childByAutoId();
                        inviteRef.setValue(invite.toAnyObject());
                        
                        // Add to LISTS
                        self.listRef.child("inviteIDs").child(inviteRef.key).setValue(ServerValue.timestamp());
                        
                        // Add to USERS
                        let recipientUserRef = self.usersRef.child(recipientID);
                        recipientUserRef.child("inviteIDs").child(inviteRef.key).setValue(ServerValue.timestamp());
                        
                        self.reloadData();
                    }
                }
            }
        }
        saveAction.isEnabled = false;
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel);
        
        alert.addTextField { emailTextField in
            emailTextField.autocapitalizationType = .words;
            emailTextField.keyboardType = .emailAddress;
            emailTextField.placeholder = "Recipient username";
        }
        
        alert.setupTextFields();
        
        alert.addAction(cancelAction);
        alert.addAction(saveAction);
        
        present(alert, animated: true, completion: nil);
    }
    
    // MARK: - Overridden Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.usersRef.child(Auth.auth().currentUser!.uid).observe(.value) { snapshot in
            let snapshotValue = snapshot.value as! [String: Any];
            self.currentUsername = snapshotValue["username"] as! String;
        }
        
        self.listRef = Database.database().reference(withPath: "lists").child(listID);
        listRef.observeSingleEvent(of: .value) { snapshot in
            if let snapshotValue = snapshot.value as? [String: Any] {
                let ownerID = snapshotValue["ownerID"] as! String;
                self.usersRef.child(ownerID).observeSingleEvent(of: .value) { snapshot in
                    if let snapshotValue = snapshot.value as? [String: Any] {
                        self.listOwnerName = snapshotValue["name"] as! String;
                        self.reloadData();
                    }
                }
            }
        }
        
        // Load joined users
        listRef.child("memberIDs").observe(.value) { snapshot in
            var loadingMembers = false;
            
            self.joinedUsers.removeAll();
            for case let snapshot as DataSnapshot in snapshot.children.sorted(by: {
                (($0 as! DataSnapshot).value as! Int) < (($1 as! DataSnapshot).value as! Int)
            }) {
                loadingMembers = true;
                let memberID = snapshot.key;
                
                self.usersRef.child(memberID).observeSingleEvent(of: .value) { snapshot in
                    if(!(snapshot.value is NSNull)) { // If snapshot has data, load User
                        let joinedUser = User(snapshot: snapshot);
                        self.joinedUsers.append(joinedUser);
                    } else { // If snapshot doesn't contain data, delete memberID
                        self.listRef.child("memberIDs").child(memberID).removeValue();
                    }
                    self.reloadData();
                }
            }
            if(!loadingMembers) { self.reloadData(); }
        }
        
        // Load inviteIDs
        listRef.child("inviteIDs").observe(.value) { snapshot in
            var loadingInvites = false;
            
            self.invites.removeAll();
            for case let snapshot as DataSnapshot in snapshot.children.sorted(by: {
                (($0 as! DataSnapshot).value as! Int) < (($1 as! DataSnapshot).value as! Int)
            }) {                loadingInvites = true;
                let inviteID = snapshot.key;
                
                self.invitesRef.child(inviteID).observeSingleEvent(of: .value) { snapshot in
                    if(!(snapshot.value is NSNull)) { // If snapshot has data load Invite
                        let invite = Invite(snapshot: snapshot, completionHandler: self.reloadData);
                        self.invites.append(invite);
                    } else { // If snapshot doesn't contain data, delete inviteID
                        self.listRef.child("inviteIDs").child(inviteID).removeValue();
                        self.reloadData();
                    }
                }
            }
            if(!loadingInvites) { self.reloadData(); }
        }
    }
    
    func reloadData() {
        self.tableView.reloadData();
        Utility.hideActivityIndicator();
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return joinedUsers.count + invites.count + 1;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "membersCell")!;
        
        if(indexPath.row == 0) {
            cell.textLabel!.text = listOwnerName;
            cell.detailTextLabel!.text = "Owner";
        } else if(indexPath.row <= joinedUsers.count) {
            let index = indexPath.row-1; // Offset due to owner
            
            cell.textLabel!.text = joinedUsers[index].name;
            cell.detailTextLabel!.text = "Joined";
        } else {
            let index = indexPath.row-joinedUsers.count-1; // Offset due to owner+members
            
            cell.textLabel!.text = invites[index].recipientName;
            cell.detailTextLabel!.text = "Invited";
        }
        
        return cell;
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row != 0;
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        switch(editingStyle) {
        case .delete:
            if(indexPath.row <= joinedUsers.count) {
                let index = indexPath.row-1;
                let member = joinedUsers[index];
                
                // Delete USER from LIST
                self.listRef.child("memberIDs").child(member.id).removeValue();
                
                // Delete LIST from USER
                self.usersRef.child(member.id).child("listID").child(self.listID).removeValue();
            } else {
                let index = indexPath.row-joinedUsers.count-1;
                let invitedUser = invites[index];
                invitedUser.delete();
            }
            break;
        default:
            break;
        }
    }
}
