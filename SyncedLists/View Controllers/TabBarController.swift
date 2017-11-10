//
//  TabBarController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/10/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import UIKit

class TabBarController: UITabBarController {
    let usersRef = Database.database().reference(withPath: "users");
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let invitesItem = self.tabBar.items![1];
        let userID = Auth.auth().currentUser!.uid;

        usersRef.child(userID).child("inviteIDs").observe(.value, with: { snapshot in
            let inviteCount = Int(snapshot.childrenCount);
            invitesItem.badgeValue = inviteCount > 0 ? "\(inviteCount)" : nil;
        });
    }

}
