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
    var page: GopherPage?
    
    override var windowNibName : String! {
        return "MainWindow"
    }
    
    override func windowDidLoad() {
        go(home)
    }
    
    func go(_ url: URL) {
        print("Going to \(url)...")
        urlTextField.stringValue = url.absoluteString
        submit(sender: nil)
    }
    
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
            
            go(url)
            return
        }
        
        listener.use()
    }

    @IBAction func submit(sender: AnyObject?) {
        let url = URL(string: urlTextField.stringValue)
        
        guard url != nil else {
            return
        }
        
        let page = GopherPage(url: url!)
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
        self.page = page
    }

    func save() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.showsTagField = true
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
