//
//  LoginViewController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/5/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    // MARK: - IBActions
    @IBAction func unwindToLogin(segue:UIStoryboardSegue) { }

    // MARK: - IBOutlets
    @IBOutlet var buttons: [UIButton]!
    
    // MARK: - Overridden Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for button in buttons {
            button.layer.cornerRadius = 5;
        }
    }
}
