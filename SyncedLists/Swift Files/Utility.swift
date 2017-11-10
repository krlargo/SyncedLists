//
//  Utility.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/8/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import Foundation
import UIKit

class Utility {
    // Mark: - Activity Indicator
    static var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView();
    
    class func showActivityIndicator(in parentView: UIView?) {
        guard let parentView = parentView else {
            return;
        }
        
        activityIndicator.activityIndicatorViewStyle = .whiteLarge;
        activityIndicator.center = CGPoint(x: 0, y: 0);
        activityIndicator.color = UIColor(displayP3Red: 66/255, green: 178/255, blue: 91/255, alpha: 1.0);
        activityIndicator.frame = CGRect(x: parentView.frame.midX,
                                         y: parentView.frame.midY,
                                         width: 0, height: 0);
        activityIndicator.hidesWhenStopped = true;

        parentView.addSubview(activityIndicator);
        activityIndicator.startAnimating();
    }
    
    class func hideActivityIndicator() {
        activityIndicator.stopAnimating();
    }
    
    // Mark: - AutoDismissing Alert Message
    class func presentErrorAlert(message: String, from viewController: UIViewController) {
        let errorAlert = UIAlertController(title: "Error", message: "\n\(message)\n\n", preferredStyle: .alert);
        viewController.present(errorAlert, animated: true, completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                errorAlert.dismiss(animated: true, completion: {
                    Utility.hideActivityIndicator();
                });
            })
        });
    }
}
