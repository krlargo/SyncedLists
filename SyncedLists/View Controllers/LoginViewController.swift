//
//  LoginViewController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/5/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import UIKit

class LoginViewController: UIViewController {
    var handle: AuthStateDidChangeListenerHandle?

    // MARK: - IBOutlets
    @IBOutlet var buttons: [UIButton]!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // MARK: - IBActions
    @IBAction func unwindToLogin(segue:UIStoryboardSegue) { }
    
    @IBAction func login(_ sender: Any) {
        Utility.showActivityIndicator(in: self.view);
        
        var loginCredentials = self.emailTextField.text!;
        let password = self.passwordTextField.text!
        
        if(loginCredentials.isAlphanumeric) { // Is a username due to lack of "@" character
            let usernamesRef = Database.database().reference(withPath: "usernames");
            usernamesRef.child(loginCredentials).observeSingleEvent(of: .value) { snapshot in
                if(!(snapshot.value is NSNull)) {
                    let userID = snapshot.value as! String;
                    let usersRef = Database.database().reference(withPath: "users");
                    usersRef.child(userID).child("email").observeSingleEvent(of: .value) { snapshot in
                        loginCredentials = snapshot.value as! String;
                        self.signIn(with: loginCredentials, password: password);
                    }
                } else {
                    Utility.presentErrorAlert(message: "The username \"\(loginCredentials)\" does not exist.", from: self);
                }
            }
        } else {
            self.signIn(with: loginCredentials, password: password);
        }
    }
    
    func signIn(with loginCredentials: String, password: String) {
        Auth.auth().signIn(withEmail: loginCredentials, password: password, completion: { (user, error) in
            let defaults = UserDefaults.standard;
            
            if let error = error { // Attempt login if account already exists
                defaults.setValue(nil, forKey: "lastLoggedInEmail");
                Utility.presentErrorAlert(message: error.localizedDescription, from: self);
            } else {
                defaults.setValue(self.emailTextField.text!, forKey: "lastLoggedInEmail");
                self.performSegue(withIdentifier: "loginSegue", sender: nil);
            }
            Utility.hideActivityIndicator();
        });
    }
    
    @IBAction func signUp(_ sender: Any) {
        let alert = UIAlertController(title: "Register", message: "", preferredStyle: .alert);
        
        let saveAction = UIAlertAction(title: "Sign Up", style: .default) { action in
            let displayName = alert.textFields![0].text!;
            let username = alert.textFields![1].text!;
            let email = alert.textFields![2].text!;
            let password = alert.textFields![3].text!;
            let confirmPassword = alert.textFields![4].text!;
            
            // Passwords must match
            if(password != confirmPassword) {
                Utility.presentErrorAlert(message: "Your passwords don't match.", from: self);
                return;
            }
            
            // Username must be unique
            let usernamesRef = Database.database().reference(withPath: "usernames");
            let usernameRef = usernamesRef.child(username);
            usernameRef.observeSingleEvent(of: .value) { snapshot in
                if(!(snapshot.value is NSNull)) {
                    Utility.presentErrorAlert(message: "The username \"\(username)\" is already taken.", from: self);
                    return;
                }
            }
            
            // Username should be alphanumeric
            if(!username.isAlphanumeric) {
                Utility.presentErrorAlert(message: "The username \"\(username)\" is invalid; usernames can only contain letters and numbers.", from: self);
                return;
            }
            
            Utility.showActivityIndicator(in: self.view);
            self.signUpUser(displayName: displayName, username: username, email: email, password: password);
        }
        saveAction.isEnabled = false;
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel);
        
        alert.addTextField { displayNameTextField in
            displayNameTextField.autocapitalizationType = .words;
            displayNameTextField.delegate = self;
            displayNameTextField.placeholder = "Display Name";
            displayNameTextField.tag = 1;
        }
        
        alert.addTextField { usernameTextField in
            usernameTextField.delegate = self;
            usernameTextField.placeholder = "Username";
            usernameTextField.tag = 1;
        }
        
        alert.addTextField { emailTextField in
            emailTextField.keyboardType = .emailAddress;
            emailTextField.placeholder = "Email";
        }
        
        alert.addTextField { passwordTextField in
            passwordTextField.isSecureTextEntry = true;
            passwordTextField.placeholder = "Password";
        }
        
        alert.addTextField(configurationHandler: { confirmPasswordTextField in
            confirmPasswordTextField.isSecureTextEntry = true;
            confirmPasswordTextField.placeholder = "Confirm Password";
        })
    
        alert.setupTextFields();
        
        alert.addAction(cancelAction);
        alert.addAction(saveAction);
        
        present(alert, animated: true, completion: nil);
    }
    
    func signUpUser(displayName: String, username: String, email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { user, error in
            if(error == nil) {
                // Login and add user metadata to database
                Auth.auth().signIn(withEmail: email, password: password);
                let currentUser = Auth.auth().currentUser!
                let changeRequest = currentUser.createProfileChangeRequest();
                changeRequest.displayName = displayName;
                changeRequest.commitChanges(completion: { error in
                    if(error == nil) {
                        // Add user to USERS
                        let usersRef = Database.database().reference(withPath: "users");
                        let newUserRef = usersRef.child(currentUser.uid);
                        newUserRef.child("name").setValue(currentUser.displayName);
                        newUserRef.child("email").setValue(currentUser.email);
                        newUserRef.child("username").setValue(username);
                        
                        // Add user to EMAILS
                        let emailsRef = Database.database().reference(withPath: "emails");
                        emailsRef.child(User.emailToID(currentUser.email!)).setValue(currentUser.uid);
                        
                        Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
                            if let error = error {
                                Utility.presentErrorAlert(message: error.localizedDescription, from: self);
                            } else {
                                self.performSegue(withIdentifier: "loginSegue", sender: nil);
                                Utility.hideActivityIndicator();
                            }
                        });
                    } else {
                        Utility.presentErrorAlert(message: error!.localizedDescription, from: self);
                    }
                });
            } else {
                Utility.presentErrorAlert(message: error!.localizedDescription, from: self);
            }
        }
    }
    
    // MARK: - Overridden Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for button in buttons {
            button.layer.cornerRadius = 5;
        }
        
        // Setup textfields
        let defaults = UserDefaults.standard;
        let lastLoggedInEmail = defaults.value(forKey: "lastLoggedInEmail") as? String;
        
        emailTextField.clearButtonMode = .whileEditing;
        emailTextField.delegate = self;
        emailTextField.text = lastLoggedInEmail;
        
        passwordTextField.clearButtonMode = .whileEditing;
        passwordTextField.delegate = self;
        
        let dismissKeyboardGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard));
        self.view.addGestureRecognizer(dismissKeyboardGesture);
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);

        passwordTextField.text?.removeAll();

        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            guard let _ = Auth.auth().currentUser else { return; }
            self.performSegue(withIdentifier: "loginSegue", sender: nil);
        }
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch (textField) {
        case emailTextField:
            passwordTextField.becomeFirstResponder();
        case passwordTextField:
            login(self);
        default:
            return true;
        }
        return true;
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Allow deletions
        if(string == "") {
            return true;
        }
        
        if(textField.tag == 1 &&
            textField.text!.count > 10) {
            return false;
        }
        return true;
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true);
    }
}
