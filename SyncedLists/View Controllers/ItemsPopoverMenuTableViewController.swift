//
//  ItemsPopoverMenuTableViewController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/9/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import UIKit

class ItemsPopoverMenuTableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView();
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3;
    }
}
