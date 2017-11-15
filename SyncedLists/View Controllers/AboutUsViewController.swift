//
//  AboutUsViewController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/15/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import UIKit
import MessageUI

class AboutUsViewController: UIViewController, MFMailComposeViewControllerDelegate {
    @IBOutlet weak var appIconImageView: UIImageView!
    @IBOutlet weak var versionLabel: UILabel!
    
    @IBAction func sendEmail(_ sender: Any) {
        if(!MFMailComposeViewController.canSendMail()) {
            Utility.presentErrorAlert(message: "Mail services not available.", from: self);
            return;
        }
        
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white];
        
        let composeVC = MFMailComposeViewController();
        composeVC.mailComposeDelegate = self;
        
        composeVC.setToRecipients(["KevinLargoApps@gmail.com"]);
        composeVC.setSubject("[SyncedLists] - ");
        //composeVC.setMessageBody("Hello from California!", isHTML: false)
        
        self.present(composeVC, animated: true, completion: nil);
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        /*switch (result) {
         case .cancelled:
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
         alert(parentView: self.collectionViewVC.view, message: "Message cancelled.", shape: .square);
         }
         case .saved:
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
         alert(parentView: self.collectionViewVC.view, message: "Draft saved.", shape: .square)
         }
         case .failed:
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
         alert(parentView: self.collectionViewVC.view, message: "Send failed.", shape: .square);
         }
         case .sent:
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
         alert(parentView: self.collectionViewVC.view, message: "Message sent.", shape: .square);
         }
         }*/
        
        controller.dismiss(animated: true, completion: nil);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let size = appIconImageView.frame.size;
        appIconImageView.layer.cornerRadius = size.width/5;
        appIconImageView.clipsToBounds = true;

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.versionLabel.text = "Version " + version;
        } else {
            versionLabel.text = "";
        }
        
    }
}
