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

class MainWindowController: NSWindowController {
    
    @IBOutlet weak var urlTextField: NSTextField!
    @IBOutlet weak var contentWebView: WebView!
    
    override var windowNibName : String! {
        return "MainWindow"
    }
    
    override func windowDidLoad() {
        let urlStr = "gopher://gopher.floodgap.com"
        let url = URL(string: "gopher://gopher.floodgap.com")
        urlTextField.stringValue = urlStr
        
        guard url != nil else {
            return
        }
        
        let page = GopherPage(url: url!)
        page.status.signal.observe(on: UIScheduler()).observeValues { _ in
            if page.status.value == .Parsed {
                guard let response = page.response else {
                    return
                }
                let html = "<html><body><pre>" + response.body + "</pre></body></html>"
                let url = URL(string: page.request!.url.path)
                self.contentWebView.mainFrame.loadHTMLString(html, baseURL: url)
            }
        }
        page.load()
    }
    
}
