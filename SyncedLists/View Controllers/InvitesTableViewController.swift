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
    
    //var invites: [(id: String, listName: String, senderName: String)] = [];
    var invites: [Invite] = [];
    var user: User!
    var handle: AuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        user = User(authData: Auth.auth().currentUser!);
        
        // Load inviteIDs from USER
        let userRef = usersRef.child(user.id);
        userRef.child("inviteIDs").observe(.value, with: { snapshot in
            var loadingInvites = false;
            Utility.showActivityIndicator(in: self.view!);
            
            // Load user's invites
            self.invites.removeAll();
            for case let snapshot as DataSnapshot in snapshot.children {
                loadingInvites = true;
                //Utility.showActivityIndicator(in: self.navigationController!.view!);
                
                let inviteID = snapshot.key;

                self.invitesRef.observeSingleEvent(of: .value, with: { snapshot in
                    // Check if inviteID exists in INVITES
                    if(snapshot.hasChild(inviteID)) {
                        // Load INVITE metadata
                        self.invitesRef.child(inviteID).observeSingleEvent(of: .value, with: { snapshot in
                            let invite = Invite(snapshot: snapshot, completionHandler: self.reloadData);
                            self.invites.append(invite);
                        });
                    }
                    // Delete inviteID from USER
                    else {
                        userRef.child("inviteIDs").child(inviteID).removeValue();
                    }
                });
                //Utility.showActivityIndicator(in: self.navigationController!.view!);
            }
            
            if(!loadingInvites) {
                self.reloadData();
            }
        }); // Load user invites
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
        if(invites.isEmpty) { return; }
        presentInviteAlert(index: indexPath.row);
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if(invites.isEmpty) { return; }
        
        let invite = invites[indexPath.row];
        
        switch(editingStyle) {
        case .delete:
            invite.delete();
        default:
            break;
        }
        
        tableView.reloadData();
    }
    
    func presentInviteAlert(index: Int) {
        let invite = invites[index];
        
        let inviteAlert = UIAlertController(title: "Invite", message: "\(invite.senderName!) has invited you to edit \"\(invite.listName!)\".", preferredStyle: .alert);
        
        let acceptAction = UIAlertAction(title: "Accept", style: .default, handler: { alert in
            // Add recipientID to LIST's membersIDs
            let listRef = self.listsRef.child(invite.listID);
            listRef.child("memberIDs").child(invite.recipientID).setValue(true);
            
            // Add listID to USER's listIDs
            let userRef = self.usersRef.child(invite.recipientID);
            userRef.child("listIDs").child(invite.listID).setValue(true);
            
            // Delete invite
            invite.delete();
            
            self.reloadData();
        });
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil);
        
        inviteAlert.addAction(cancelAction);
        inviteAlert.addAction(acceptAction);
        
        present(inviteAlert, animated: true, completion: nil);
    }
}
