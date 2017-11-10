//
//  InvitesTableViewController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/9/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import UIKit

class InvitesTableViewController: UITableViewController {
    // MARK: - Variables
    let usersRef = Database.database().reference(withPath: "users");
    let listsRef = Database.database().reference(withPath: "lists");
    let invitesRef = Database.database().reference(withPath: "invites");
    var userRef: DatabaseReference!
    
    var invites: [(id: String, listName: String, senderName: String)] = [];
    var user: User!
    var handle: AuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        user = User(authData: Auth.auth().currentUser!);
        
        // Load user invites
        usersRef.child(user.id).child("inviteIDs").observe(.value, with: { snapshot in
            // Used so we know to stop activity animator if there are no invites
            var loadingInvites = false;

            Utility.showActivityIndicator(in: self.navigationController!.view!)
            self.invites.removeAll();
            
            // For each user invite
            for case let snapshot as DataSnapshot in snapshot.children {
                loadingInvites = true;
                
                // Load invite metadata
                let inviteID = snapshot.key;
                self.invitesRef.child(inviteID).observeSingleEvent(of: .value, with: { snapshot in
                    let snapshotValue = snapshot.value as! [String: String];
                    let listID = snapshotValue["listID"]!;
                    let senderID = snapshotValue["senderID"]!;
                    
                    // Load list name
                    var listName = "", senderName = "";
                    self.listsRef.child(listID).observeSingleEvent(of: .value, with: { snapshot in
                        let snapshotValue = snapshot.value as! [String: String];
                        listName = snapshotValue["name"]!;
                        
                        // Load sender name
                        self.usersRef.child(senderID).observeSingleEvent(of: .value, with: { snapshot in
                            let snapshotValue = snapshot.value as! [String: Any];
                            senderName = snapshotValue["name"] as! String!;
                            
                            let invite = (inviteID, listName, senderName);
                            
                            self.invites.append(invite);
                            
                            defer {
                                self.tableView.reloadData();
                                Utility.hideActivityIndicator();
                            }
                        }); // Load sender name
                    }); // Load list name
                }); // Load invite metadata
            } // For each invite
            
            if(!loadingInvites) {
                self.tableView.reloadData();
                Utility.hideActivityIndicator();
            }
        }); // Load user invites
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (invites.isEmpty) ? 1 : invites.count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "invitesCell");
        
        if(invites.isEmpty) {
            cell!.textLabel!.text = "No Invites";
            cell!.textLabel!.textColor = UIColor.lightGray;
            cell!.detailTextLabel?.text = "";

            return cell!;
        }
        
        cell!.textLabel!.text = invites[indexPath.row].listName;
        cell!.textLabel!.textColor = UIColor.darkText;
        cell!.detailTextLabel!.text = invites[indexPath.row].senderName;
        
        return cell!;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.dequeueReusableCell(withIdentifier: "invitesCell");
        
        if(invites.isEmpty) { return; }
        
        presentInviteAlert(index: indexPath.row);
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if(invites.isEmpty) { return; }
        
        let invite = invites[indexPath.row];
        
        switch(editingStyle) {
        case .delete:
            // Remove invite from user
            self.usersRef.child(self.user.id).child("inviteIDs").child(invite.id).removeValue();
            self.invitesRef.child(invite.id).removeValue();
        default:
            break;
        }
        
        tableView.reloadData();
    }
    
    func presentInviteAlert(index: Int) {
        let invite = invites[index];
        
        let inviteAlert = UIAlertController(title: "Invitation", message: "\(invite.senderName) has invited you to edit \"\(invite.listName)\".", preferredStyle: .alert);
        
        let acceptAction = UIAlertAction(title: "Accept", style: .default, handler: { alert in
            // Do nothing for now
            Utility.presentErrorAlert(message: "Accepted Invite!", from: self);
        });
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil);
        
        inviteAlert.addAction(cancelAction);
        inviteAlert.addAction(acceptAction);
        
        present(inviteAlert, animated: true, completion: nil);
    }
}
