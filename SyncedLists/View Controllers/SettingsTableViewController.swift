//
//  SettingsTableViewController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/8/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import UIKit

class SettingsTableViewController: UITableViewController {
    // MARK: - Variables
    var user: User!
    var userRef: DatabaseReference!
    let emailsRef = Database.database().reference(withPath: "emails");
    let usernamesRef = Database.database().reference(withPath: "usernames");

    var firebaseUser: FirebaseAuth.User!
    var handle: AuthStateDidChangeListenerHandle!
    
    var originalUsername: String!
    
    // Used for keeping track of section & item counts
    var tableData: [[UITableViewCell]]!;
    
    // MARK: - IBOutlets
    @IBOutlet weak var nameCell: UITableViewCell!
    @IBOutlet weak var usernameCell: UITableViewCell!
    @IBOutlet weak var emailCell: UITableViewCell!
    @IBOutlet weak var passwordCell: UITableViewCell!
    @IBOutlet weak var contactCell: UITableViewCell!
    @IBOutlet weak var deleteAccountCell: UITableViewCell!
    
    // MARK: - IBActions
    @IBAction func logout(_ sender: Any) {
        do {
            try Auth.auth().signOut();
        } catch(let error) {
            Utility.presentErrorAlert(message: error.localizedDescription, from: self);
        }
    }

    // MARK: - Overridden Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        firebaseUser = Auth.auth().currentUser!
        user = User(authData: firebaseUser);
        userRef = Database.database().reference(withPath: "users").child(user.id);
        
        tableData = [
            [nameCell, usernameCell, emailCell, passwordCell],
            [contactCell],
            [deleteAccountCell]
        ]
        
        self.nameCell.detailTextLabel?.text = firebaseUser.displayName;
        self.emailCell.detailTextLabel?.text = firebaseUser.email;
        
        userRef.child("username").observeSingleEvent(of: .value) { snapshot in
            self.originalUsername = snapshot.value as! String;
            self.usernameCell.detailTextLabel?.text = "@" + self.originalUsername;
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                self.user = User(authData: user);
            } else {
                self.performSegue(withIdentifier: "logoutSegue", sender: self);
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tableData.count;
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].count;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath);
        
        if(cell == nameCell) {
            presentEditNameAlert();
        } else if(cell == usernameCell) {
            presentEditUsernameAlert();
        } else if(cell == emailCell) {
            presentEditEmailAlert();
        } else if(cell == passwordCell) {
            presentEditPasswordAlert();
        } else if(cell == deleteAccountCell) {
            presentDeleteAccountAlert();
        }
    }
    
    func presentEditNameAlert() {
        let editNameAlert = UIAlertController(title: "Edit Name", message: "", preferredStyle: .alert);
        
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { action in
            let changeRequest = self.firebaseUser.createProfileChangeRequest();
            let newDisplayName = editNameAlert.textFields![0].text!;
            changeRequest.displayName = newDisplayName
            Utility.showActivityIndicator(in: self.navigationController?.view);

            changeRequest.commitChanges(completion: { error in
                if let error = error {
                    Utility.presentErrorAlert(message: error.localizedDescription, from: self);
                } else {
                    self.userRef.child("name").setValue(newDisplayName);
                    self.nameCell.detailTextLabel?.text = self.firebaseUser.displayName;
                }
                Utility.hideActivityIndicator();
            });
        });
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil);
        
        editNameAlert.addTextField { textField in
            textField.autocapitalizationType = .words;
            textField.text = self.firebaseUser.displayName;
        }
        
        editNameAlert.setupTextFields();
        
        editNameAlert.addAction(cancelAction);
        editNameAlert.addAction(saveAction);
        
        present(editNameAlert, animated: true, completion: nil);
    }
    
    func presentEditUsernameAlert() {
        let editUsernameAlert = UIAlertController(title: "Edit Username", message: "", preferredStyle: .alert);
        
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { action in
            let newUsername = editUsernameAlert.textFields![0].text!;

            // Validate newUsername
            
            // Update in USERS
            self.userRef.child("username").setValue(newUsername);

            // Update in USERNAMES
            self.usernamesRef.child(self.originalUsername).removeValue(); // Remove old value
            self.usernamesRef.child(newUsername).setValue(firebaseUser.uid); // Insert new value
            
            // Update usernameCell
            self.usernameCell.detailTextLabel?.text = "@" + newUsername;
        });
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil);
        
        editUsernameAlert.addTextField { textField in
            textField.autocapitalizationType = .words;
            textField.text = self.originalUsername;
        }
        
        editUsernameAlert.setupTextFields();
        
        editUsernameAlert.addAction(cancelAction);
        editUsernameAlert.addAction(saveAction);
        
        present(editUsernameAlert, animated: true, completion: nil);
    }
    
    func presentEditEmailAlert() {
        let editEmailAlert = UIAlertController(title: "Edit Email", message: "", preferredStyle: .alert);
        
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { action in
            let newEmail = editEmailAlert.textFields![0].text!;
            let oldEmail = firebaseUser.email!;
            
            Utility.showActivityIndicator(in: self.navigationController?.view);
            
            self.firebaseUser.updateEmail(to: newEmail, completion: { error in
                if let error = error {
                    Utility.presentErrorAlert(message: error.localizedDescription, from: self);
                } else {
                    // Update in USERS
                    self.userRef.child("email").setValue(newEmail);

                    // Update in EMAILS
                    let newEmailAsKey = newEmail.replacingOccurrences(of: ".", with: ",");
                    let oldEmailAsKey = oldEmail.replacingOccurrences(of: ".", with: ",");
                    
                    self.emailsRef.child(oldEmailAsKey).removeValue(); // Remove old value
                    self.emailsRef.child(newEmailAsKey).setValue(firebaseUser.uid); // Insert new value

                    self.emailCell.detailTextLabel?.text = self.firebaseUser.email;
                }
                Utility.hideActivityIndicator();
            });
        });
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil);
        
        editEmailAlert.addTextField { textField in
            textField.text = self.firebaseUser.email;
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
            let oldPassword = editPasswordAlert.textFields![0].text!;
            let newPassword = editPasswordAlert.textFields![1].text!;
            let confirmNewPassword = editPasswordAlert.textFields![2].text!;
            
            // Confirm that old password is known
            let credential = EmailAuthProvider.credential(withEmail: self.firebaseUser.email!, password: oldPassword);
            self.firebaseUser.reauthenticate(with: credential, completion: { error in
                if let error = error {
                    Utility.presentErrorAlert(message: error.localizedDescription, from: self);
                    return;
                } else {
                    // Confirm new password match
                    if(newPassword != confirmNewPassword) {
                        Utility.presentErrorAlert(message: "Your passwords don't match.", from: self);
                        return;
                    }
                    
                    // If all checks out, begin update password
                    Utility.showActivityIndicator(in: self.navigationController?.view);
                    
                    self.firebaseUser.updatePassword(to: newPassword, completion: { error in
                        if let error = error {
                            Utility.presentErrorAlert(message: error.localizedDescription, from: self);
                        }
                        Utility.hideActivityIndicator();
                    });
                }
            });
        });
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil);
        
        editPasswordAlert.addTextField { textField in
            textField.isSecureTextEntry = true;
            textField.placeholder = "Old Password";
        }

        editPasswordAlert.addTextField { textField in
            textField.isSecureTextEntry = true;
            textField.placeholder = "New Password";
        }

        editPasswordAlert.addTextField { textField in
            textField.isSecureTextEntry = true;
            textField.placeholder = "Confirm New Password";
        }

        editPasswordAlert.setupTextFields();
        
        editPasswordAlert.addAction(cancelAction);
        editPasswordAlert.addAction(saveAction);
        
        present(editPasswordAlert, animated: true, completion: nil);
    }
    
    func presentDeleteAccountAlert() {
        let deleteAccountAlert = UIAlertController(title: "Are you sure you want to delete your account?", message: "\nThis action is irreversible.", preferredStyle: .alert);
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { alert in
            Utility.showActivityIndicator(in: self.navigationController?.view);
            
            self.firebaseUser.delete(completion: { error in
                if let error = error {
                    Utility.presentErrorAlert(message: error.localizedDescription, from: self);
                } else {
                    // Delete related queries
                    self.user.delete();
                    self.performSegue(withIdentifier: "logoutSegue", sender: self);
                }
                Utility.hideActivityIndicator();
            });
        });
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil);
        
        deleteAccountAlert.addAction(cancelAction);
        deleteAccountAlert.addAction(deleteAction);
        
        present(deleteAccountAlert, animated: true, completion: nil);
    }
}
