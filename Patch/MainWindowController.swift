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
    
    override var windowNibName : String! {
        return "MainWindow"
    }
    
    override func windowDidLoad() {
        let url = "gopher://gopher.floodgap.com"
        urlTextField.stringValue = url
        submit(sender: nil)
    }
    
    func webView(_ webView: WebView!, decidePolicyForNavigationAction actionInformation: [AnyHashable : Any]!, request: URLRequest!, frame: WebFrame!, decisionListener listener: WebPolicyDecisionListener!) {
        
        let navTypeObject = (actionInformation[WebActionNavigationTypeKey] as? Int) ?? 0
        let navTypeCode: WebNavigationType = WebNavigationType(rawValue: navTypeObject) ?? .other
        
        if navTypeCode != .other {
            listener.ignore()
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
                guard let response = page.response else {
                    return
                }
                let html = response.html
                let url = URL(string: page.request!.url.path)
                self.contentWebView.mainFrame.loadHTMLString(html, baseURL: url)
            }
        }
        page.load()
    }
    
}
