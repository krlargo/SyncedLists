//
//  AlertController+Extension.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/8/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import Foundation
import UIKit

extension UIAlertController {
    func setupTextFields() {
        for textField in self.textFields! {
            textField.addTarget(self, action: #selector(self.alertTextFieldChanged), for: .editingChanged);
            textField.autocapitalizationType = .words;
            textField.clearButtonMode = .whileEditing;
        }
    }
    
    // Make sure all textfields are filled before enabling submit button
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
        
        alert.actions[1].isEnabled = (count == alert.textFields?.count);
    }
}
