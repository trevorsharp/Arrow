//
//  CommentsViewController.swift
//  Arrow
//
//  Created by Trevor Sharp on 4/7/16.
//  Copyright © 2016 Trevor Sharp. All rights reserved.
//

import UIKit

class CommentsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {

    // MARK: Overridden Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Text view
        addCommentText.delegate = self
        addCommentText.textContainerInset = UIEdgeInsetsZero
        
        // Table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Notification for keyboard
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentsViewController.keyboardWillChangeFrame(_:)), name: UIKeyboardWillChangeFrameNotification, object: nil)
        
        refresh()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: Properties
    var postToDisplay: Post = Post(0) // Passed from previous view controller
    private var display: [Comment] = []
    private var firstType: Bool = true
    private let defaults = NSUserDefaults.standardUserDefaults()
    private var error: NSError? { didSet{ self.errorHandling(error) } }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var addCommentView: UIView!
    @IBOutlet weak var addCommentText: UITextView!
    @IBOutlet weak var addCommentConstraint: NSLayoutConstraint!
    @IBOutlet weak var addCommentHeightConstraint: NSLayoutConstraint!
    @IBAction func addCommentButton(sender: UIButton) {
        if !firstType {
            if addCommentText.text != "" {
                postComment(addCommentText.text)
            }
        }
    }
    @IBAction func dismiss(sender: UITapGestureRecognizer) {
        addCommentText.resignFirstResponder()
    }
    
    // MARK: Functions
    private func refresh() {
        suspendUI()
        let qos = Int(QOS_CLASS_BACKGROUND.rawValue)
        dispatch_async(dispatch_get_global_queue(qos, 0)){ () -> Void in
            let table = Table(type: 4)
            if let postID = self.postToDisplay.identifier {
                let results = table.getObjectsWithKeyValue(["post": postID], limit: 0, error: &self.error) as! [Comment]
                self.display.removeAll()
                self.display = results
            }
            dispatch_async(dispatch_get_main_queue()){ () -> Void in
                self.updateUI()
            }
        }
    }
    
    private func suspendUI() {
        addCommentText.resignFirstResponder()
        addCommentText.text = "Add a comment..."
        firstType = true
        addCommentView?.hidden = true
        spinner?.hidden = false
        spinner?.startAnimating()
    }
    
    private func updateUI() {
        addCommentView?.hidden = false
        display.sortInPlace { "\($0.date)".compare("\($1.date)") == .OrderedAscending }
        tableView.reloadData()
        spinner?.stopAnimating()
        spinner?.hidden = true
    }
    
    private func removeComment(index: Int) {
        if let commentID = display[index].identifier {
            display.removeAtIndex(index)
            tableView.reloadData()
            let qos = Int(QOS_CLASS_USER_INITIATED.rawValue)
            dispatch_async(dispatch_get_global_queue(qos, 0)){ () -> Void in
                let table = Table(type: 4)
                table.deleteObjectWithStringKeys(["_id": commentID], error: &self.error)
            }
        }
    }
    
    private func postComment(comment: String) {
        suspendUI()
        addCommentHeightConstraint.constant = 50
        
        // Remove leading and trailing spaces
        let text = comment.stringByTrimmingCharactersInSet(
            NSCharacterSet.whitespaceAndNewlineCharacterSet()
        )
        
        // Post comment
        let qos = Int(QOS_CLASS_BACKGROUND.rawValue)
        dispatch_async(dispatch_get_global_queue(qos, 0)){ () -> Void in
            if let postID = self.postToDisplay.identifier {
                let commentObject = Comment(comment: text)
                commentObject.addToDatabase(postID, error: &self.error)
            }
            dispatch_async(dispatch_get_main_queue()){ () -> Void in
                self.refresh()
            }
        }
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        if firstType {
            firstType = false
            textView.text = ""
        }
    }
    
    func textViewDidChange(textView: UITextView) {
        let font: UIFont = UIFont.systemFontOfSize(15)
        switch round((textView.contentSize.height) / font.lineHeight) {
        case 1:
            addCommentHeightConstraint.constant = 50
        case 2:
            textView.scrollRangeToVisible(NSRange(location:0, length:0))
            addCommentHeightConstraint.constant = 68
        default:
            break
        }
    }
    
    private func errorHandling(error: NSError?) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if error != nil {
                print("Error: Code \(error!.code), \(error!.description)")
                switch error!.code {
                case 201: // No internet connection alert
                    let alert = UIAlertController(
                        title: "Offline",
                        message: "Please check your internet connection.",
                        preferredStyle:  UIAlertControllerStyle.Alert
                    )
                    alert.addAction(UIAlertAction(
                        title: "Dismiss",
                        style: .Cancel)
                    { (action: UIAlertAction) -> Void in
                        // Do nothing
                        }
                    )
                    self.presentViewController(alert, animated: true, completion: nil)
                default: // Error alert
                    let alert = UIAlertController(
                        title: "Error \(error!.code)",
                        message: "Something went wrong.",
                        preferredStyle:  UIAlertControllerStyle.Alert
                    )
                    alert.addAction(UIAlertAction(
                        title: "Dismiss",
                        style: .Cancel)
                    { (action: UIAlertAction) -> Void in
                        }
                    )
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
        }
    }
}

extension CommentsViewController { // TableView implementation
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return display.count }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return CGFloat.min }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("commentCell", forIndexPath: indexPath) as! CommentTableViewCell
        cell.commentToDisplay = display[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if display[indexPath.row].user.userID == defaults.stringForKey(UserDefaults().keyForUserID) {
            return true
        } else if postToDisplay.user.userID == defaults.stringForKey(UserDefaults().keyForUserID) {
            return true
        } else {
            return false
        }
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle { return .Delete }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            removeComment(indexPath.row)
        }
    }
}

extension CommentsViewController {
    
    func keyboardWillChangeFrame(notification: NSNotification) {
        let screenSize = UIScreen.mainScreen().bounds.height
        let keyboardOrigin = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue().origin.y
        let keyboardHeight = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue().height
        if keyboardOrigin == screenSize {
            addCommentConstraint.constant = 0
        } else {
            if keyboardHeight != nil {
                if let tabBarHeight = self.tabBarController?.tabBar.frame.size.height {
                    addCommentConstraint.constant = keyboardHeight! - tabBarHeight
                }
            }
        }
    }
}
