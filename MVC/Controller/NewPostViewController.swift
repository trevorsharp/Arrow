//
//  NewPostViewController.swift
//  Arrow
//
//  Created by Trevor Sharp on 4/20/16.
//  Copyright © 2016 Trevor Sharp. All rights reserved.
//

import UIKit

class NewPostViewController: UIViewController, UITextViewDelegate {

    // MARK: Overriden Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentsViewController.keyboardWillChangeFrame(_:)), name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        textView.resignFirstResponder()
    }
    
    // MARK: Properties
    var classToPostTo: Class = Class(classTitle: nil, schoolID: nil, professorID: nil) // Passed from previous view controller
    private var firstType: Bool = true
    private var error: NSError? { didSet{ self.errorHandling(error) } }
    private var postResult: Post?
    
    @IBOutlet weak var textView: UITextView!
    @IBAction func postButton(sender: UIButton) {
        if textView.text != "Type your post here..." && textView.text != "" {
            post()
        }
    }
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    // MARK: Functions
    private func post() {
        suspendUI()
        
        // Remove leading and trailing spaces
        var text = textView.text
        text = text.stringByTrimmingCharactersInSet(
            NSCharacterSet.whitespaceAndNewlineCharacterSet()
        )
        
        // Post to class
        if let classID = self.classToPostTo.identifier {
            let qos = Int(QOS_CLASS_BACKGROUND.rawValue)
            dispatch_async(dispatch_get_global_queue(qos, 0)){ () -> Void in
                let post = Post(postText: text, classIdentifier: classID)
                self.postResult = post
                post.addToDatabase(&self.error)
                dispatch_async(dispatch_get_main_queue()){ () -> Void in
                    self.performSegueWithIdentifier("goBack", sender: self)
                }
            }
        }
    }
    
    private func suspendUI() {
        textView.resignFirstResponder()
        textView.hidden = true
        spinner.startAnimating()
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        if firstType {
            firstType = false
            textView.text = ""
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

extension NewPostViewController {
    
    func keyboardWillChangeFrame(notification: NSNotification) {
        let screenSize = UIScreen.mainScreen().bounds.height
        let keyboardOrigin = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue().origin.y
        let keyboardHeight = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue().height
        if keyboardOrigin == screenSize {
            bottomConstraint.constant = 0
        } else {
            if keyboardHeight != nil {
                bottomConstraint.constant = keyboardHeight!
            }
        }
    }
}


