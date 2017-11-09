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
    static var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView();
    
    class func showActivityIndicator(in parentView: UIView) {
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
}
