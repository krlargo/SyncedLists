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
    
    var invites: [String] = [];
    var user: User!
    var handle: AuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
            tableView.allowsSelection = false;
            
            cell!.textLabel!.text = "No Invites";
            cell!.textLabel!.textColor = UIColor.lightGray;
            
            return cell!;
        } else {
            tableView.allowsSelection = true;
            
            cell!.textLabel!.text = "";
        }
        
        return cell!;
    }
}
