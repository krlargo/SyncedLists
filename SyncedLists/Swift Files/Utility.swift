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
    static var backgroundView = UIView();
    
    class func showActivityIndicator(in parentView: UIView?) {
        guard let parentView = parentView else {
            return;
        }
        
        backgroundView = UIView();
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.3);
        backgroundView.layer.cornerRadius = 10;
        backgroundView.frame = CGRect(x: 0, y: 0, width: 75, height: 75);
        backgroundView.center = CGPoint(x: parentView.frame.midX, y: parentView.frame.midY);
        
        activityIndicator = UIActivityIndicatorView();
        activityIndicator.activityIndicatorViewStyle = .whiteLarge;
        activityIndicator.color = UIColor(displayP3Red: 66/255, green: 178/255, blue: 91/255, alpha: 1.0);
        activityIndicator.center = CGPoint(x: backgroundView.frame.width/2,
                                           y: backgroundView.frame.height/2);
        activityIndicator.hidesWhenStopped = true;
        
        backgroundView.addSubview(activityIndicator);
        parentView.addSubview(backgroundView);
        
        activityIndicator.startAnimating();
    }
    
    class func hideActivityIndicator() {
        backgroundView.removeFromSuperview();
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
