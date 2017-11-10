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
    var usersRef = Database.database().reference(withPath: "users");
    var listRef: DatabaseReference!
    var listID: String!
    var listOwnerName: String!
    
    var members: [(id: String, name: String)] = [];
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.listRef = Database.database().reference(withPath: "lists").child(listID);

        // Get list ownerID
        listRef.observeSingleEvent(of: .value, with: { snapshot in
            Utility.showActivityIndicator(in: self.navigationController!.view!);
            
            let snapshotValue = snapshot.value as! [String: Any];
            let ownerID = snapshotValue["ownerID"] as! String;
            
            // Get owner's name
            self.usersRef.child(ownerID).observeSingleEvent(of: .value, with: { snapshot in
                let snapshotValue = snapshot.value as! [String: Any];
                self.listOwnerName = snapshotValue["name"] as! String;
                
                self.tableView.reloadData();
                Utility.hideActivityIndicator();
            });
        });
        
        // Get memberIDs
        listRef.child("memberIDs").observe(.value, with: { snapshot in
            var loadingMembers = false;
            
            Utility.showActivityIndicator(in: self.navigationController!.view!);
            
            self.members.removeAll();
            
            for case let snapshot as DataSnapshot in snapshot.children {
                loadingMembers = true;
                
                let memberID = snapshot.key;
                self.usersRef.child(memberID).child("name").observeSingleEvent(of: .value, with: { snapshot in
                    let memberName = snapshot.value as! String;
                    self.members.append((memberID, memberName));
                });
                
                self.tableView.reloadData();
                Utility.hideActivityIndicator();
            }
            
            if(!loadingMembers) {
                self.tableView.reloadData();
                Utility.hideActivityIndicator();
            }
        });
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count + 1;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "membersCell")!;

        if(indexPath.row == 0) {
            cell.textLabel!.text = listOwnerName;
            cell.detailTextLabel!.text = "Owner";
            return cell;
        }
        
        let index = indexPath.row-1; // Offset due to owner
        
        cell.textLabel!.text = members[index].name;
        cell.detailTextLabel!.text = "Invited/Joined";
        
        return cell;
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if(members.isEmpty) { return; }
        
        switch(editingStyle) {
        case .delete:
            break;
        default:
            break;
        }
    }
}
