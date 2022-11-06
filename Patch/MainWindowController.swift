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

class MainWindowController: NSWindowController, WKNavigationDelegate {
    
    @IBOutlet weak var urlTextField: NSTextField!
    @IBOutlet weak var contentWebView: WKWebView!
    
    let home = URL(string: "gopher://gopher.floodgap.com")!
    var history: [URL] = []
    var historyI = -1
    var page: GopherPage?
    var loaded = false
    
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

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        if navigationAction.navigationType == WKNavigationType.other {
            return WKNavigationActionPolicy.allow
        }
        if let url = navigationAction.request.mainDocumentURL {
            load(url)
        }
        return WKNavigationActionPolicy.cancel
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
        loaded = false
        page.status.signal.observe(on: UIScheduler()).observeValues { _ in
            if page.status.value == .Parsed && self.loaded == false {
                self.loaded = true
                guard page.response != nil else {
                    return
                }
                let html = page.html
                let url = URL(string: page.request!.url.path)
                self.contentWebView.loadHTMLString(html, baseURL: url)
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
    
    /*
     Print current page
     */
    @available(macOS 11.0, *)
    @IBAction func printAs(sender: AnyObject?) {
        let info = NSPrintInfo.shared
        let operation = contentWebView.printOperation(with: info)
        operation.view?.frame = contentWebView.bounds

        guard let window = contentWebView.window else { return }

        operation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
    }
}
