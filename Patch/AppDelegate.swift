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
    
    @objc dynamic var backEnabled: Bool {
        guard let mainWindowController = topMainWindowController else {
            return false
        }
        return mainWindowController.backEnabled
    }
    
    @objc dynamic var forwardEnabled: Bool {
        guard let mainWindowController = topMainWindowController else {
            return false
        }
        return mainWindowController.forwardEnabled
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NotificationCenter.default.addObserver(self, selector: #selector(onWindowBecomeMain), name: NSWindow.didBecomeMainNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onWindowWillClose), name: NSWindow.willCloseNotification, object: nil)
        newWindow(url: nil)
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
    
    func newWindow(url: URL?) {
        let mainWindowController: MainWindowController
        if let url = url {
            mainWindowController = MainWindowController(url: url)
        }
        else {
            mainWindowController = MainWindowController()
        }
        mainWindowController.window?.makeKeyAndOrderFront(self)
        mainWindowController.window?.makeFirstResponder(mainWindowController.window)
        mainWindowControllers.insert(mainWindowController)
    }
    
    func newWindowIfNone() {
        if mainWindowControllers.isEmpty {
            newWindow(url: nil)
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
        newWindow(url: nil)
    }
    
    @IBAction func openPreferences(sender: AnyObject?) {
        openPreferences()
    }

    @IBAction func openLocation(sender: AnyObject?) {
        newWindowIfNone()
        topMainWindowController?.urlTextField.selectText(nil)
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            newWindow(url: url)
        }
    }
}
