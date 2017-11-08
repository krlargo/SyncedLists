//
//  HomeViewController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/8/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

    @IBOutlet var buttons: [UIButton]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for button in buttons {
            button.layer.cornerRadius = 5;
        }
    }
}
