//
//  GopherPage.swift
//  Patch
//
//  Created by Jacob Budin on 4/8/17.
//  Copyright © 2017 Jacob Budin. All rights reserved.
//

import Foundation
import ReactiveSwift

class GopherPage {
    var request: GopherRequest?
    var response: GopherResponse?
    var status: MutableProperty<GopherStatus> = MutableProperty(.Queued)
    
    var html: String {
        
        let cssPath = Bundle.main.path(forResource: "GopherPageStyle", ofType: "css")
        guard let resolvedCssPath = cssPath else {
            fatalError("Gopher page stylesheet could not be located")
        }
        
        var contentHtml: String
        
        if (self.response?.isDirectory)! {
            print("Showing directory...")
            contentHtml = parseDirectory().map({
                $0.html
            }).joined()
        }
        else {
            print("Showing file...")
            contentHtml = parseRaw()
        }
        
        return "<html><head><link href=\"file://\(resolvedCssPath)\" rel=\"stylesheet\"></head><body>" + contentHtml + "</body></html>"
    }
    
    let lineSeparator = String(bytes: [13, 10], encoding: String.Encoding.ascii)!
    let terminatingSequence = [".", ""]
    
    init(url: URL) {
        self.request = GopherRequest(url: url)
    }
    
    func load() {
        guard let request = self.request else {
            return
        }
        
        self.status.value = .Loading
        
        request.load() {
            (data) in
            self.status.value = .Loaded
            self.response = GopherResponse(data: data)
            self.status.value = .Parsed
        }
    }
    
    private func parseRaw() -> String {
        guard let body = self.response?.body else {
            return ""
        }
        
        let html = body.components(separatedBy: "\n\n").map({
            "<p>" + $0 + "</p>"
        }).joined()
        
        return html
    }
    
    private func parseDirectory() -> [GopherResponsePart] {
        guard let parts = self.response?.body.components(separatedBy: lineSeparator) else {
            return []
        }
        
        let completeResponse = parts.suffix(2).elementsEqual(terminatingSequence)
        if completeResponse == false {
            return []
        }
        
        return parts.dropLast(2).map {
            return GopherResponsePart(string: $0)
        }
    }
}
