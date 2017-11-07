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
            }
        });
    }
    
    @IBAction func signUp(_ sender: Any) {
        let alert = UIAlertController(title: "Register",
                                      message: "",
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Sign Up", style: .default) { action in
            let emailField = alert.textFields![0];
            let passwordField = alert.textFields![1];

            Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!) { user, error in
                if(error == nil) { // Attempt login if account already exists
                    Auth.auth().signIn(withEmail: self.emailTextField.text!, password: self.passwordTextField.text!);
                }
             }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default);
        
        alert.addTextField { textEmail in
            textEmail.placeholder = "Email";
        }
        
        alert.addTextField { textPassword in
            textPassword.isSecureTextEntry = true;
            textPassword.placeholder = "Password";
        }
        
        alert.addAction(saveAction);
        alert.addAction(cancelAction);
        
        present(alert, animated: true, completion: nil);
    }
    
    // MARK: - Overridden Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for button in buttons {
            button.layer.cornerRadius = 5;
        }
        
        // Setup keyboard dismissal
        let dismissKeyboardGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard));
        self.view.addGestureRecognizer(dismissKeyboardGesture);
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true);
    }
}
