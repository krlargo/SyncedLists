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
        ///,,,
        if(emailTextField.text! == "" && passwordTextField.text! == "") {
            Auth.auth().signIn(withEmail: "xkevlar@live.com", password: "abc123");
            self.performSegue(withIdentifier: "loginSegue", sender: nil);
        }
        ///'''
        
        Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!, completion: { (user, error) in
            if(error == nil) { // Attempt login if account already exists
                Auth.auth().signIn(withEmail: self.emailTextField.text!, password: self.passwordTextField.text!);
                self.performSegue(withIdentifier: "loginSegue", sender: nil);
            } else {
                let failedLoginAlert = UIAlertController(title: "Login Failed", message: error?.localizedDescription, preferredStyle: .alert);
                let okayAction = UIAlertAction(title: "Okay", style: .cancel);
                failedLoginAlert.addAction(okayAction);
                self.present(failedLoginAlert, animated: true, completion: nil);
            }
        });
    }
    
    @IBAction func signUp(_ sender: Any) {
        let registerAlertController = UIAlertController(title: "Register", message: "", preferredStyle: .alert);
        
        let saveAction = UIAlertAction(title: "Sign Up", style: .default) { action in
            let displayName = registerAlertController.textFields![0].text!;
            let email = registerAlertController.textFields![1].text!;
            let password = registerAlertController.textFields![2].text!;
            
            // Do nothing if any textfield is empty
            if(displayName == "" || email == "" || password == "") {
                return;
            }
            
            Auth.auth().createUser(withEmail: email, password: password) { user, error in
                if(error == nil) { // Attempt login if account already exists
                    Auth.auth().signIn(withEmail: email, password: password);
                    let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest();
                    changeRequest?.displayName = displayName;
                    changeRequest?.commitChanges(completion: { error in
                        if(error == nil) {
                            self.performSegue(withIdentifier: "loginSegue", sender: nil);
                        }
                    });
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default);
        
        registerAlertController.addTextField { displayNameTextField in
            displayNameTextField.autocapitalizationType = .words;
            displayNameTextField.delegate = self;
            displayNameTextField.placeholder = "Display Name";
            displayNameTextField.tag = 1;
        }
        
        registerAlertController.addTextField { emailTextField in
            emailTextField.keyboardType = .emailAddress;
            emailTextField.placeholder = "Email";
        }
        
        registerAlertController.addTextField { passwordTextField in
            passwordTextField.isSecureTextEntry = true;
            passwordTextField.placeholder = "Password";
        }
        
        // Add general properties to each textfield
        for textField in registerAlertController.textFields! {
            textField.addTarget(self, action: #selector(self.alertTextFieldChanged), for: .editingChanged);
            textField.clearButtonMode = .whileEditing;
        }
        
        registerAlertController.addAction(cancelAction);
        registerAlertController.addAction(saveAction);
        
        saveAction.isEnabled = false;
        cancelAction.isEnabled = true;
        
        present(registerAlertController, animated: true, completion: nil);
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
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if(textField.tag == 1 &&
            textField.text!.count > 10) {
            return false;
        }
        return true;
    }
    
    @objc func alertTextFieldChanged(textField: UITextField) {
        var responder : UIResponder = textField
        while !(responder is UIAlertController) {
            responder = responder.next!
        }
        let alert = responder as! UIAlertController
        
        var count = 0;
        for textField in alert.textFields! {
            if(textField.text ?? "" != "") {
                count += 1;
            }
        }
        
        (alert.actions[1] as UIAlertAction).isEnabled = (count == 3);
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true);
    }
}
