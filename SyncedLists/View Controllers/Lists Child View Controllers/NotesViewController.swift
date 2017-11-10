//
//  NotesViewController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/9/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import UIKit

class NotesViewController: UIViewController {
    let listsRef = Database.database().reference(withPath: "lists");
    var userRef: DatabaseReference!
    
    var user: User!
    var listID: String!
    var handle: AuthStateDidChangeListenerHandle?
    
    @IBOutlet weak var notesTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
}
