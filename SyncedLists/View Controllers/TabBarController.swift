//
//  TabBarController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/9/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let myTabBarItem1 = (self.tabBar.items?[0])! as UITabBarItem
        myTabBarItem1.image = UIImage(named: "Unselected")?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        myTabBarItem1.selectedImage = UIImage(named: "Selected ")?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        myTabBarItem1.title = ""
        myTabBarItem1.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)

        let listsItem = self.tabBar.items?[0];
        listsItem?.image
        
        let invitesItem = self.tabBar.items?[1]!;
        
        let settingsItem = self.tabBar.items?[2]!;
    }
}
