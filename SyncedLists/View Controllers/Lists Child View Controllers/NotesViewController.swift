//
//  NotesViewController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/9/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import FirebaseDatabase
import UIKit

class NotesViewController: UIViewController {
    let listsRef = Database.database().reference(withPath: "lists");
    
    var listID: String!
    
    @IBOutlet weak var notesTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Utility.showActivityIndicator(in: self.navigationController!.view!);
        
        // Set line spacing
        let style = NSMutableParagraphStyle();
        style.lineSpacing = 8;
        let attributes: [NSAttributedStringKey: Any] = [NSAttributedStringKey.paragraphStyle: style, NSAttributedStringKey.font: self.notesTextView.font];
        
        let listRef = listsRef.child(listID);
        listRef.child("notes").observe(.value, with: { snapshot in
            let text = snapshot.value as? String;
            self.notesTextView.attributedText = NSAttributedString(string: text ?? "", attributes: attributes);
            Utility.hideActivityIndicator();
        });
    }
}
