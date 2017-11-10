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
    
    var invites: [(listID: String, senderID: String)] = [];
    var user: User!
    var handle: AuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utility.showActivityIndicator(in: self.navigationController!.view!)
        
        user = User(authData: Auth.auth().currentUser!);
        usersRef.child(user.id).child("inviteIDs").observe(.value, with: { snapshot in

            self.invites.removeAll();
            
            // Get all of the user's inviteIds
            for case let snapshot as DataSnapshot in snapshot.children {
                let inviteID = snapshot.key;
                self.invitesRef.child(inviteID).observeSingleEvent(of: .value, with: { snapshot in
                    let snapshotValue = snapshot.value as! [String: String];
                    let listID = snapshotValue["listID"]!;
                    let senderID = snapshotValue["senderID"]!;
                    
                    // Get list name
                    var listName = "", senderName = "";
                    self.listsRef.child(listID).observeSingleEvent(of: .value, with: { snapshot in
                        let snapshotValue = snapshot.value as! [String: String];
                        listName = snapshotValue["name"]!;
                        
                        // Get sender's name
                        self.usersRef.child(senderID).observeSingleEvent(of: .value, with: { snapshot in
                            let snapshotValue = snapshot.value as! [String: Any];
                            senderName = snapshotValue["name"] as! String!;
                            
                            let invite = (listName, senderName);
                            
                            
                            self.invites.append(invite);
                            self.tableView.reloadData();
                            Utility.hideActivityIndicator();
                        });
                    });
                });
            }
        });
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
            
            return cell!;
        }
        
        cell!.textLabel!.text = invites[indexPath.row].listID;
        cell!.textLabel!.textColor = UIColor.darkText;
        
        return cell!;
    }
}
