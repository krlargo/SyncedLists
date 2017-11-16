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
    var emailsRef = Database.database().reference(withPath: "emails");
    var invitesRef = Database.database().reference(withPath: "invites");
    var listRef: DatabaseReference!
    
    var listID: String!
    var listOwnerName: String!
    
    var joinedUsers: [User] = [];
    var invites: [Invite] = [];
    
    // MARK: - IBActions
    @IBAction func addMember(_ sender: Any) {
        func isValidEmail(testStr:String) -> Bool {
            return true;
            let emailRegEx = "/.+@.+\\..+/i";
            let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            return emailTest.evaluate(with: testStr)
        }
        
        let alert = UIAlertController(title: "Invite Member", message: "", preferredStyle: .alert);
        
        let saveAction = UIAlertAction(title: "Invite", style: .default, handler: { _ in
            guard let textField = alert.textFields?.first,
                let email = textField.text?.lowercased() else { return; }
            
            // Email validation
            if(email == Auth.auth().currentUser!.email!) {
                Utility.presentErrorAlert(message: "You cannot invite yourself.", from: self);
                return;
            } else if(!isValidEmail(testStr: email)) {
                Utility.presentErrorAlert(message: "Invalid email format.", from: self);
                return;
            }
            
            Utility.showActivityIndicator(in: self.navigationController!.view!);
            
            // Save invite
            self.emailsRef.observeSingleEvent(of: .value, with: { snapshot in
                let recipientEmailAsID = User.emailToID(email);
                
                if(snapshot.hasChild(recipientEmailAsID)) {
                    let snapshotValue = snapshot.value as! [String: String];

                    let senderID = Auth.auth().currentUser!.uid;
                    let recipientID = snapshotValue[recipientEmailAsID]!;

                    let invite = Invite(senderID: senderID, recipientID: recipientID, listID: self.listID)

                    self.listRef.child("inviteIDs").observeSingleEvent(of: .value, with: { snapshot in
                        // If list's inviteIDs already contains email
                        if(snapshot.hasChild(recipientID)) {
                            Utility.presentErrorAlert(message: "User with email \"\(email)\" has already been invited.", from: self)
                        } else { // Invite user
                            // Add to INVITES
                            let inviteRef = self.invitesRef.childByAutoId();
                            inviteRef.setValue(invite.toAnyObject());
                            
                            // Add to LISTS
                            self.listRef.child("inviteIDs").child(inviteRef.key).setValue(true);

                            // Add to USERS
                            let recipientUserRef = self.usersRef.child(recipientID);
                            recipientUserRef.child("inviteIDs").child(inviteRef.key).setValue(true);
                            
                            self.reloadData();
                        }
                    });
                } else {
                    Utility.presentErrorAlert(message: "User with email \"\(email)\" does not exist.", from: self);
                }
                self.reloadData();
            });
            self.reloadData();
        });
        saveAction.isEnabled = false;
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel);
        
        alert.addTextField { emailTextField in
            emailTextField.autocapitalizationType = .words;
            emailTextField.keyboardType = .emailAddress;
            emailTextField.placeholder = "Recipient Email";
        }
        
        alert.setupTextFields();
        
        alert.addAction(cancelAction);
        alert.addAction(saveAction);
        
        present(alert, animated: true, completion: nil);
    }
    
    // MARK: - Overridden Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.listRef = Database.database().reference(withPath: "lists").child(listID);
        
        // Get list ownerID
        listRef.observe(.value, with: { snapshot in
            //Utility.showActivityIndicator(in: self.navigationController!.view!);
            
            let snapshotValue = snapshot.value as! [String: Any];
            let ownerID = snapshotValue["ownerID"] as! String;
            
            // Get owner's name
            self.usersRef.child(ownerID).observeSingleEvent(of: .value, with: { snapshot in
                let snapshotValue = snapshot.value as! [String: Any];
                self.listOwnerName = snapshotValue["name"] as! String;
                self.reloadData();
            });
        });
        
        // Load joined users
        listRef.child("memberIDs").observe(.value, with: { snapshot in
            var loadingMembers = false;

            self.joinedUsers.removeAll();
            for case let snapshot as DataSnapshot in snapshot.children {
                loadingMembers = true;
                let memberID = snapshot.key;
                
                self.usersRef.observeSingleEvent(of: .value, with: { snapshot in
                    if(snapshot.hasChild(memberID)) { // Load user if memberID exists in USERS
                        let userSnapshot = snapshot.childSnapshot(forPath: memberID);
                        let joinedUser = User(snapshot: userSnapshot);
                        self.joinedUsers.append(joinedUser);
                    } else { // Delete memberID from list if memberID does not exist in USERS
                        self.listRef.child("memberID").child(memberID).removeValue();
                    }
                    self.reloadData();
                });
            }
            if(!loadingMembers) { self.reloadData(); }
        });
        
        // Load inviteIDs
        listRef.child("inviteIDs").observe(.value, with: { snapshot in
            var loadingInvites = false;

            self.invites.removeAll();
            for case let snapshot as DataSnapshot in snapshot.children {
                loadingInvites = true;
                let inviteID = snapshot.key;

                self.invitesRef.observeSingleEvent(of: .value, with: { snapshot in
                    if(snapshot.hasChild(inviteID)) { // Load invite if inviteID exists in INVITES
                        let inviteSnapshot = snapshot.childSnapshot(forPath: inviteID);
                        let invite = Invite(snapshot: inviteSnapshot, completionHandler: self.reloadData);
                        self.invites.append(invite);
                    } else { // Delete inviteID from list if inviteID does not exist in INVITES
                        self.listRef.child("inviteID").child(inviteID).removeValue();
                        self.reloadData();
                    }
                });
            }
            if(!loadingInvites) { self.reloadData(); }
        });
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
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row != 0;
    }
}
