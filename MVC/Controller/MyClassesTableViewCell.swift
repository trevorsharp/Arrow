//
//  MyClassesTableViewCell.swift
//  Arrow
//
//  Created by Trevor Sharp on 3/29/16.
//  Copyright © 2016 Trevor Sharp. All rights reserved.
//

import UIKit

class MyClassesTableViewCell: UITableViewCell {
    
    // MARK: Properties
    var classToDisplay: Class? {
        didSet {
            updateUI()
        }
    }
    
    @IBOutlet weak var courseTitle: UILabel!
    @IBOutlet weak var professorName: UILabel!
    @IBOutlet weak var numberOfUsersLabel: UILabel!

    // MARK: Functions
    func updateUI() {
        
        // Reset information
        courseTitle.text = nil
        professorName.text = nil
        numberOfUsersLabel.text = nil
        
        // Add new information
        if let newClass = self.classToDisplay {
            courseTitle.text = newClass.title
            numberOfUsersLabel.text = "\(newClass.numberOfMembers)"
            professorName.text = newClass.professorObject.getName()
        }
    }
}