//
//  AppDelegate.swift
//  Patch
//
//  Created by Jacob Budin on 3/15/17.
//  Copyright © 2017 Jacob Budin. All rights reserved.
//

import Cocoa

extension NSWindowController {
    var appDelegate: AppDelegate {
        return NSApplication.shared.delegate as! AppDelegate
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var topMainWindowController: MainWindowController?
    var mainWindowControllers: Set<MainWindowController> = []
    var preferencesWindowController: PreferencesWindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NotificationCenter.default.addObserver(self, selector: #selector(onWindowBecomeMain), name: NSWindow.didBecomeMainNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onWindowWillClose), name: NSWindow.willCloseNotification, object: nil)
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
    
    @objc func onWindowWillClose(notification: Notification) {
        let windowController = (notification.object as? NSWindow)?.delegate
        
        if let mainWindowController = windowController as? MainWindowController {
            mainWindowControllers.remove(mainWindowController)
            if mainWindowController == topMainWindowController {
                topMainWindowController = nil
            }
            mainWindowController.dismissController(self)
        }
        
        if let preferencesWindowController = windowController as? PreferencesWindowController {
            self.preferencesWindowController = nil
            preferencesWindowController.dismissController(self)
        }
    }
    
    @objc func onWindowBecomeMain(notification: Notification) {
        let windowController = (notification.object as? NSWindow)?.delegate
        
        if let mainWindowController = windowController as? MainWindowController {
            topMainWindowController = mainWindowController
        }
    }
    
    func newWindow() {
        let mainWindowController = MainWindowController()
        mainWindowController.window?.makeKeyAndOrderFront(self)
        mainWindowController.window?.makeFirstResponder(mainWindowController.window)
        mainWindowControllers.insert(mainWindowController)
    }
    
    func newWindowIfNone() {
        if mainWindowControllers.isEmpty {
            newWindow()
        }
    }
    
    func openPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        preferencesWindowController!.window?.makeKeyAndOrderFront(self)
        preferencesWindowController!.window?.makeFirstResponder(preferencesWindowController!.window)
    }
    
    @IBAction func newDocument(sender: AnyObject?) {
        newWindow()
    }
    
    @IBAction func openPreferences(sender: AnyObject?) {
        openPreferences()
    }

    @IBAction func openLocation(sender: AnyObject?) {
        newWindowIfNone()
        topMainWindowController?.urlTextField.selectText(nil)
    }
}
