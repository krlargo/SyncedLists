//
//  LoginViewController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/5/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import FirebaseAuth
import UIKit

class LoginViewController: UIViewController {
    // MARK: - IBOutlets
    @IBOutlet var buttons: [UIButton]!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // MARK: - IBActions
    @IBAction func unwindToLogin(segue:UIStoryboardSegue) { }
    
    @IBAction func login(_ sender: Any) {
        Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!, completion: { (user, error) in
            if(error == nil) { // Attempt login if account already exists
                Auth.auth().signIn(withEmail: self.emailTextField.text!, password: self.passwordTextField.text!);
                self.performSegue(withIdentifier: "loginSegue", sender: nil);
            } else {
                let failedLoginAlert = UIAlertController(title: "Login Failed", message: "Your email or password is incorrect.", preferredStyle: .alert);
                let okayAction = UIAlertAction(title: "Okay", style: .cancel);
                failedLoginAlert.addAction(okayAction);
                self.present(failedLoginAlert, animated: true, completion: nil);
            }
        });
    }
    
    @IBAction func signUp(_ sender: Any) {
        func registerUser(email: String, password: String) {
            Auth.auth().createUser(withEmail: email, password: password) { user, error in
                if(error == nil) { // Attempt login if account already exists
                    Auth.auth().signIn(withEmail: email, password: password);
                    self.performSegue(withIdentifier: "loginSegue", sender: nil);
                }
            }
        }
        
        if(emailTextField.text ?? "" != "" &&
            passwordTextField.text ?? "" != "") {
            registerUser(email: emailTextField.text!, password: passwordTextField.text!)
        } else {
            let registerAlert = UIAlertController(title: "Register", message: "", preferredStyle: .alert);
            
            let saveAction = UIAlertAction(title: "Sign Up", style: .default) { action in
                let emailField = registerAlert.textFields![0];
                let passwordField = registerAlert.textFields![1];
                registerUser(email: emailField.text!, password: passwordField.text!);
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .default);
            
            registerAlert.addTextField { textEmail in
                textEmail.placeholder = "Email";
            }
            
            registerAlert.addTextField { textPassword in
                textPassword.isSecureTextEntry = true;
                textPassword.placeholder = "Password";
            }
            
            registerAlert.addAction(saveAction);
            registerAlert.addAction(cancelAction);
            
            present(registerAlert, animated: true, completion: nil);
        }
    }
    
    // MARK: - Overridden Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for button in buttons {
            button.layer.cornerRadius = 5;
        }
        
        // Setup textfields
        emailTextField.delegate = self;
        passwordTextField.delegate = self;
        let dismissKeyboardGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard));
        self.view.addGestureRecognizer(dismissKeyboardGesture);
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
    
    @objc func dismissKeyboard() {
        view.endEditing(true);
    }
}
