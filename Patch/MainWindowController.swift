//
//  MainWindowController.swift
//  Patch
//
//  Created by Jacob Budin on 3/15/17.
//  Copyright © 2017 Jacob Budin. All rights reserved.
//

import AppKit
import Foundation
import WebKit
import ReactiveSwift

class MainWindowController: NSWindowController, WebPolicyDelegate {
    
    @IBOutlet weak var urlTextField: NSTextField!
    @IBOutlet weak var contentWebView: WebView!
    
    let home = URL(string: "gopher://gopher.floodgap.com")!
    var history: [URL] = []
    var historyI = -1
    var page: GopherPage?
    
    override var windowNibName : String! {
        return "MainWindow"
    }
    
    override func windowDidLoad() {
        // Load home page
        load(home)
    }
    
    /*
     Load previous state in history
     */
    @IBAction func back(sender: AnyObject?) {
        // Disallow when on "first" page
        if historyI == 0 {
            return
        }
        
        historyI -= 1
        let previousUrl = history[historyI]
        load(previousUrl, affectsHistory: false)
    }

    /*
     Undo previous state in history
     */
    @IBAction func forward(sender: AnyObject?) {
        // Disallow when on "last" page
        if history.count == historyI + 1 {
            return
        }
        
        historyI += 1
        let nextUrl = history[historyI]
        load(nextUrl, affectsHistory: false)
    }

    /*
     Listen to home page clicks
     */
    @IBAction func home(sender: AnyObject?) {
        load(home)
    }

    /*
     Capture webview link clicks
     */
    func webView(_ webView: WebView!, decidePolicyForNavigationAction actionInformation: [AnyHashable : Any]!, request: URLRequest!, frame: WebFrame!, decisionListener listener: WebPolicyDecisionListener!) {
        
        let navUrl = (actionInformation[WebActionOriginalURLKey] as? URL) ?? nil
        let navTypeObject = (actionInformation[WebActionNavigationTypeKey] as? Int) ?? 0
        let navTypeCode: WebNavigationType = WebNavigationType(rawValue: navTypeObject) ?? .other
        
        if navTypeCode != .other {
            print("Hijacked page load")
            listener.ignore()
            
            guard let url = navUrl else {
                return
            }
            
            load(url)
            return
        }
        
        listener.use()
    }

    /*
     Listen to submit of URL input
     */
    @IBAction func submit(sender: AnyObject?) {
        print("submit")
        guard let url = URL(string: urlTextField.stringValue) else {
            return
        }

        load(url)
    }

    /*
     Load URL in webview
     */
    func load(_ url: URL, affectsHistory: Bool = true) {
        print("Loading \(url)")
        urlTextField.stringValue = url.absoluteString

        let page = GopherPage(url: url)
        page.status.signal.observe(on: UIScheduler()).observeValues { _ in
            if page.status.value == .Parsed {
                guard page.response != nil else {
                    return
                }

                let html = page.html
                let url = URL(string: page.request!.url.path)
                self.contentWebView.mainFrame.loadHTMLString(html, baseURL: url)
            }
        }
        page.load()
        
        if affectsHistory {
            // Never modify history on same URL
            if self.history.last == url {
                return
            }
            
            // Remove any forward-facing URLs
            self.history.removeLast(self.history.count - self.historyI - 1)
            
            // Update history
            self.historyI += 1
            self.history.append(url)
        }

        self.page = page
    }

    /*
     Save current page to file
     */
    @IBAction func saveDocumentAs(sender: AnyObject?) {
        let panel = NSSavePanel()
        let url = self.page?.request?.url
        let fileName = url?.pathComponents.count != 0 ? url?.pathComponents.last : url?.host
        panel.nameFieldStringValue = "\(fileName ?? "untitled").html"
        panel.allowedFileTypes = ["html"]
        panel.allowsOtherFileTypes = false
        panel.begin { (result) in
            guard
                result.rawValue == NSFileHandlingPanelOKButton,
                let fileLocation = panel.url
            else {
                return
            }

            do {
                try self.page?.html.data(using: .utf8)?.write(to: fileLocation)
            } catch {
                // TODO: Write error
            }
        }
    }

}
