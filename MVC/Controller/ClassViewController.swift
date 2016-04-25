//
//  ClassViewController.swift
//  Arrow
//
//  Created by Trevor Sharp on 4/4/16.
//  Copyright © 2016 Trevor Sharp. All rights reserved.
//

import UIKit

class ClassViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: Overridden Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.title = classToDisplay.title
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.addSubview(self.refreshControl)
        fullRefresh()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let id = segue.identifier {
            switch id {
            case "goToComments":
                let dvc = segue.destinationViewController as! CommentsViewController
                dvc.postToDisplay = passToComments
            case "newPost":
                let dvc = segue.destinationViewController as! UINavigationController
                let ultimatedvc = dvc.viewControllers.first as! NewPostViewController
                ultimatedvc.classToPostTo = classToDisplay
            default: break
            }
        }
    }
    
    // MARK: Properties
    var classToDisplay: Class = Class(classTitle: nil, schoolID: nil, professorID: nil) // Passed from previous view controller
    var display: [Post] = []
    private var passToComments: Post = Post(0)
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ClassViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        return refreshControl
    }()
    private var refreshing = 0
    private let defaults = NSUserDefaults.standardUserDefaults()
    private var error: NSError? { didSet{ self.errorHandling(error) } }
    
    @IBAction func unwindToClass(segue: UIStoryboardSegue) {}
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Functions
    func fullRefresh() {
        refreshControl.beginRefreshing()
        refreshing += 1
        var temp: [Post] = []
        let qos = Int(QOS_CLASS_BACKGROUND.rawValue)
        dispatch_async(dispatch_get_global_queue(qos, 0)){ () -> Void in
            let table = Table(type: 3)
            if let classID = self.classToDisplay.identifier {
                let results = table.getRecentPostsWithKeyValue(["class": classID], error: &self.error)
                temp = results
            }
            self.refreshing -= 1
            dispatch_async(dispatch_get_main_queue()){ () -> Void in
                if self.refreshing == 0 {
                    // Reload UI
                    self.display = temp
                    self.updateUI()
                }
            }
        }
    }
    
    private func updateUI() {
        display.sortInPlace { "\($0.date)".compare("\($1.date)") == .OrderedDescending }
        tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    @IBAction func handleRefresh(refreshControl: UIRefreshControl) {
        fullRefresh()
    }
    
    private func errorHandling(error: NSError?) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if error != nil {
                print("Error: Code \(error!.code), \(error!.description)")
                switch error!.code {
                case 201: // No internet connection alert
                    let alert = UIAlertController(
                        title: "Offline",
                        message: "Please check your internet connection and try again.",
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

extension ClassViewController { // TableView implementation
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return display.count }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return CGFloat.min }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("postCell", forIndexPath: indexPath) as! PostTableViewCell
        cell.postToDisplay = display[indexPath.row]
        cell.likeButton.tag = indexPath.row
        cell.likeButton.addTarget(self, action: #selector(ClassViewController.like(_:)), forControlEvents: .TouchUpInside)
        cell.moreButton.tag = indexPath.row
        cell.moreButton.addTarget(self, action: #selector(ClassViewController.more(_:)), forControlEvents: .TouchUpInside)
        cell.commentButton.tag = indexPath.row
        cell.commentButton.addTarget(self, action: #selector(ClassViewController.comment(_:)), forControlEvents: .TouchUpInside)
        return cell
    }
    
    private func buttonsShouldBeEnabled(index: Int) -> Bool {
        if display[index].identifier == nil { return false }
        return true
    }
    
    @IBAction func like(sender: UIButton) { // Like button tapped
        if buttonsShouldBeEnabled(sender.tag) {
            if !display[sender.tag].liked {
                display[sender.tag].liked = true
                display[sender.tag].numberOfLikes += 1
                tableView.reloadData()
                let qos = Int(QOS_CLASS_BACKGROUND.rawValue)
                dispatch_async(dispatch_get_global_queue(qos, 0)){ () -> Void in
                    self.display[sender.tag].like(&self.error)
                }
            }
        }
    }
    
    @IBAction func comment(sender: UIButton) {
        if buttonsShouldBeEnabled(sender.tag) {
            passToComments = display[sender.tag]
            performSegueWithIdentifier("goToComments", sender: self)
        }
    }
    
    @IBAction func more(sender: UIButton) {
        if buttonsShouldBeEnabled(sender.tag) {
            let alert = UIAlertController(
                title: nil,
                message: nil,
                preferredStyle:  UIAlertControllerStyle.ActionSheet
            )
            alert.addAction(UIAlertAction(
                title: "Delete Post",
                style: .Destructive)
            { (action: UIAlertAction) -> Void in
                // Delete Post
                let post = self.display[sender.tag]
                self.display.removeAtIndex(sender.tag)
                self.updateUI()
                self.refreshing += 1
                let qos = Int(QOS_CLASS_BACKGROUND.rawValue)
                dispatch_async(dispatch_get_global_queue(qos, 0)){ () -> Void in
                    post.removeSelf(&self.error)
                    self.refreshing -= 1
                    dispatch_async(dispatch_get_main_queue()){ () -> Void in
                        self.fullRefresh()
                    }
                }
                }
            )
            alert.addAction(UIAlertAction(
                title: "Cancel",
                style: .Cancel)
            { (action: UIAlertAction) -> Void in
                // Do nothing
                }
            )
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
}