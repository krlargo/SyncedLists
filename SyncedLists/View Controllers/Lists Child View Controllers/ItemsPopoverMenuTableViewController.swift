//
//  ItemsPopoverMenuTableViewController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/9/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import FirebaseDatabase
import UIKit

protocol ItemsMenuDelegate {
    var user: User! { get };
    var itemsRef: DatabaseReference { get };
    func showMembersTVC();
    func showNotesVC();
}

class ItemsPopoverMenuTableViewController: UITableViewController {
    var delegate: ItemsMenuDelegate!
    
    // MARK: - IBOutlets
    @IBOutlet weak var addItemCell: UITableViewCell!
    @IBOutlet weak var membersCell: UITableViewCell!
    @IBOutlet weak var notesCell: UITableViewCell!
    
    // MARK: - Overridden Methods
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!;
        
        switch(cell) {
        case addItemCell:
            self.addItem();
        case membersCell:
            self.delegate.showMembersTVC();
            self.dismiss(animated: true, completion: nil);
        case notesCell:
            self.delegate.showNotesVC();
            self.dismiss(animated: true, completion: nil);
        default:
            break;
        }
    }

    func addItem() {
        let alert = UIAlertController(title: "Add Item", message: "", preferredStyle: .alert);
        
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { _ in
            guard let textField = alert.textFields?.first,
                let text = textField.text else { return; }
            
            let item = Item(name: text, addedBy: self.delegate.user);
            let itemRef = self.delegate.itemsRef.childByAutoId();
            itemRef.setValue(item.toAnyObject());
            
            self.tableView.reloadData();
            self.dismiss(animated: true, completion: nil); // Dismiss popoup menu
        });
        saveAction.isEnabled = false;
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.dismiss(animated: true, completion: nil); // Dismiss popup menu
        });
        
        alert.addTextField { itemNameTextField in
            itemNameTextField.autocapitalizationType = .words;
            itemNameTextField.placeholder = "List Name";
        }
        
        alert.setupTextFields();
        
        alert.addAction(cancelAction);
        alert.addAction(saveAction);
        
        present(alert, animated: true, completion: nil);
    }
}
