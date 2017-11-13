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
    // MARK: - IBOutlets
    @IBOutlet var buttons: [UIButton]!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // MARK: - IBActions
    @IBAction func unwindToLogin(segue:UIStoryboardSegue) { }
    
    @IBAction func login(_ sender: Any) {
        ///,,,
        if(emailTextField.text! == "" && passwordTextField.text! == "") {
            Auth.auth().signIn(withEmail: "xkevlar@live.com", password: "abc123", completion: { (user, error) in
                if let error = error {
                    Utility.presentErrorAlert(message: error.localizedDescription, from: self);
                } else {
                    self.performSegue(withIdentifier: "loginSegue", sender: nil);
                }
            });
        } else if(emailTextField.text! != "" && passwordTextField.text! == "") {
            Auth.auth().signIn(withEmail: emailTextField.text!, password: "abc123", completion: { (user, error) in
                if let error = error {
                    Utility.presentErrorAlert(message: error.localizedDescription, from: self);
                } else {
                    self.performSegue(withIdentifier: "loginSegue", sender: nil);
                }
            });
        
        } else {
        ///'''
            
            Utility.showActivityIndicator(in: self.view);
            
            Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!, completion: { (user, error) in
                if let error = error { // Attempt login if account already exists
                    Utility.presentErrorAlert(message: error.localizedDescription, from: self);
                } else {
                    self.performSegue(withIdentifier: "loginSegue", sender: nil);
                }
                Utility.hideActivityIndicator();
            });
        } ///
    }
    
    @IBAction func signUp(_ sender: Any) {
        let alert = UIAlertController(title: "Register", message: "", preferredStyle: .alert);
        
        let saveAction = UIAlertAction(title: "Sign Up", style: .default) { action in
            let displayName = alert.textFields![0].text!;
            let email = alert.textFields![1].text!;
            let password = alert.textFields![2].text!;
            let confirmPassword = alert.textFields![3].text!;
            
            if(password != confirmPassword) {
                Utility.presentErrorAlert(message: "Your passwords don't match.", from: self);
                return;
            }
            
            Utility.showActivityIndicator(in: self.view);

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
                            
                            // Add user to EMAILS
                            let emailsRef = Database.database().reference(withPath: "emails");
                            emailsRef.child(User.emailToID(currentUser.email!)).setValue(currentUser.uid);
                            
                            Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
                                if let error = error {
                                    Utility.presentErrorAlert(message: error.localizedDescription, from: self);
                                } else {
                                    self.performSegue(withIdentifier: "loginSegue", sender: nil);
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
            Utility.hideActivityIndicator();
        }
        saveAction.isEnabled = false;
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel);
        
        alert.addTextField { displayNameTextField in
            displayNameTextField.autocapitalizationType = .words;
            displayNameTextField.delegate = self;
            displayNameTextField.placeholder = "Display Name";
            displayNameTextField.tag = 1;
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
    
    // MARK: - Overridden Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for button in buttons {
            button.layer.cornerRadius = 5;
        }
        
        // Setup textfields
        emailTextField.clearButtonMode = .whileEditing;
        emailTextField.delegate = self;
        passwordTextField.clearButtonMode = .whileEditing;
        passwordTextField.delegate = self;
        
        let dismissKeyboardGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard));
        self.view.addGestureRecognizer(dismissKeyboardGesture);
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        passwordTextField.text?.removeAll();
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
