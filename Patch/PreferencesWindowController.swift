//
//  PreferencesWindowController.swift
//  Patch
//
//  Created by Jacob Budin on 11/5/22.
//  Copyright © 2022 Jacob Budin. All rights reserved.
//

import AppKit
import Foundation

class PreferencesWindowController: NSWindowController {
    
    @IBOutlet weak var homepageTextField: NSTextField!
    
    override var windowNibName : String! {
        return "PreferencesWindow"
    }
    
    @IBAction func setHomepageToCurrent(sender: AnyObject?) {
        guard let mainWindowController = appDelegate.topMainWindowController else {
            return
        }
        homepageTextField.becomeFirstResponder()
        homepageTextField.currentEditor()?.insertText(mainWindowController.urlTextField.stringValue)
        homepageTextField.selectText(nil)
    }
    
}
