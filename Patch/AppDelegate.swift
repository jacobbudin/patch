//
//  AppDelegate.swift
//  Patch
//
//  Created by Jacob Budin on 3/15/17.
//  Copyright © 2017 Jacob Budin. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var mainWindowControllers: [MainWindowController] = []

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        newWindow()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        for mainWindowController in mainWindowControllers {
            mainWindowController.window?.makeKeyAndOrderFront(self)
        }
        
        return true
    }
    
    func newWindow() {
        let mainWindowController = MainWindowController()
        mainWindowController.window?.makeKeyAndOrderFront(self)
        mainWindowController.window?.makeFirstResponder(mainWindowController)
        mainWindowControllers.append(mainWindowController)
    }
    
    @IBAction func newDocument(sender: AnyObject?) {
        newWindow()
    }

}
