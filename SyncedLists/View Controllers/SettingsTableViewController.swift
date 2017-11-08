//
//  SettingsTableViewController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/8/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import FirebaseAuth
import UIKit

class SettingsTableViewController: UITableViewController {
    
    // MARK: - Variables
    var user: User!
    var firebaseUser: FirebaseAuth.User!
    
    // MARK: - IBOutlets
    @IBOutlet weak var nameCell: UITableViewCell!
    @IBOutlet weak var emailCell: UITableViewCell!
    @IBOutlet weak var passwordCell: UITableViewCell!
    @IBOutlet weak var deleteAccountCell: UITableViewCell!
    
    // Used for keeping track of section & item counts
    var tableData = [
        ["Name", "Email", "Password"],
        ["Delete Account"]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        firebaseUser = Auth.auth().currentUser!
        user = User(authData: firebaseUser);
        
        changeRequest = firebaseUser.createProfileChangeRequest();
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tableData.count;
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].count;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath);
        
        switch(cell) {
        case nameCell:
            presentEditNameAlert();
        case emailCell:
            presentEditEmailAlert();
        case passwordCell:
            presentEditPasswordAlert();
        case deleteAccountCell:
            presentDeleteAccountAlert();
        default:
            break;
        }
    }
    
    func presentEditNameAlert() {
        let editNameAlert = UIAlertController(title: "Edit Name", message: "", preferredStyle: .alert);
        
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { action in
            let changeRequest = firebaseUser.createProfileChangeRequest();
            changeRequest.displayName = editNameAlert.textFields![0].text;
            changeRequest.commitChanges(completion: { error in
                if let error = error {
                    //let errorAlert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert);
                }
            });
        });
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil);
        
        editNameAlert.addTextField { textField in
            textField.autocapitalizationType = .words;
        }
        
        editNameAlert.setupTextFields();
        
        editNameAlert.addAction(cancelAction);
        editNameAlert.addAction(saveAction);
        
        present(editNameAlert, animated: true, completion: nil);
    }
    
    func presentEditEmailAlert() {
        let editEmailAlert = UIAlertController(title: "Edit Email", message: "", preferredStyle: .alert);
        
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { action in
            firebaseUser.updateEmail(to: newEmail, completion: { error in
                if let error = error {
                    //let errorAlert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert);
                }
            });
        });
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil);
        
        editEmailAlert.addTextField { textField in
            textField.keyboardType = .emailAddress;
        }
        
        editEmailAlert.setupTextFields();
        
        editEmailAlert.addAction(cancelAction);
        editEmailAlert.addAction(saveAction);
        
        present(editEmailAlert, animated: true, completion: nil);
    }
    
    func presentEditPasswordAlert() {
        let editPasswordAlert = UIAlertController(title: "Edit Password", message: "", preferredStyle: .alert);
        
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { action in
            firebaseUser.updatePassword(to: newPassword, completion: { error in
                if let error = error {
                    //let errorAlert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert);
                }
            });
        });
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil);
        
        editPasswordAlert.addTextField { textField in
            textField.keyboardType = .emailAddress;
        }
        
        editPasswordAlert.setupTextFields();
        
        editPasswordAlert.addAction(cancelAction);
        editPasswordAlert.addAction(saveAction);
        
        present(editPasswordAlert, animated: true, completion: nil);
    }
    
    func presentDeleteAccountAlert() {
        let deleteAccountAlert = UIAlertController(title: "Are you sure you want to delete your account?", message: "This actions is irreversible.", preferredStyle: .alert);
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { alert in
            firebaseUser.delete { error in
                {
                    if let error = error {
                        //let errorAlert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert);
                    } else {
                        // Delete related queries
                        performSegue(withIdentifier: "unwindToLogin", sender: self);
                    }
                }
            }
        });
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil);
        
        deleteAccountAlert.addAction(cancelAction);
        deleteAccountAlert.addAction(deleteAction);
        
        present(deleteAccountAlert, animated: true, completion: nil);
    }
}
