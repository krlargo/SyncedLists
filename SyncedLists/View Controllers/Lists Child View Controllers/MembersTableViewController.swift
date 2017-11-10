//
//  MembersTableViewController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/9/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import UIKit

class MembersTableViewController: UITableViewController {
    let listsRef = Database.database().reference(withPath: "lists");
    var userRef: DatabaseReference!
    
    var members: [User] = [];
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
        return (members.isEmpty) ? 1 : members.count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "membersCell")!;

        if(members.isEmpty) {
            tableView.allowsSelection = false;
            
            cell.textLabel!.text = "No Invites";
            cell.textLabel!.textColor = UIColor.lightGray;
            
            return cell;
        }
        
        tableView.allowsSelection = true;
        cell.textLabel!.text = "";

        return cell;
    }
}
