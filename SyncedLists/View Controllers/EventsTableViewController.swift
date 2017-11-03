//
//  EventsTableViewController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 10/19/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import FirebaseDatabase
import Foundation
import UIKit

class EventsTableViewController: UITableViewController {
    // MARK: - Variables
    let ref = Database.database().reference(withPath: "events");
    var events: [Event] = [];
    //var user: User!
    var user = User(uid: "Kevin", email: "krlargo@ucdavis.edu");
    
    // MARK: - IBActions
    @IBAction func addEvent(_ sender: Any) {
        let alert = UIAlertController(title: "Event", message: "Add Event", preferredStyle: .alert);
        
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { _ in
            
            guard let textField = alert.textFields?.first,
                let text = textField.text else { return; }
            
            let event = Event(name: text, owner: self.user.email);
            let eventRef = self.ref.child(text.lowercased());
            eventRef.setValue(event.toAnyObject());
            
            self.tableView.reloadData();
        });
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default);
        
        alert.addTextField();
        alert.addAction(saveAction);
        alert.addAction(cancelAction);
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: Overridden Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref.observe(.value, with: { snapshot in
            var loadedEvents: [Event] = [];
            
            for case let snapshot as DataSnapshot in snapshot.children {
                let event = Event(snapshot: snapshot, completionHandler: self.tableView.reloadData);
                loadedEvents.append(event);
            }
            
            self.events = loadedEvents;
            self.tableView.reloadData();
        })
    }
    
    // MARK: - TableView Delegate Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell");
        let event = events[indexPath.row];
        
        cell?.textLabel?.text? = event.name;
        cell?.detailTextLabel?.text? = "\(event.completedCount)/\(event.itemCount)";
        
        return cell!;
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch(editingStyle) {
        case .delete:
            return; ///
        default:
            return;
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "toItems") {
            if let indexPath = tableView.indexPathForSelectedRow {
                let itemsTVC = segue.destination as! ItemsTableViewController;
                itemsTVC.title = events[indexPath.row].name;
                itemsTVC.itemsRef = events[indexPath.row].ref?.child("items");
            }
        }
    }
}
