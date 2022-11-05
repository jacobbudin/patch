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
        let type = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        let cssName = "GopherPageStyle-" + type
        guard let cssPath = Bundle.main.path(forResource: cssName, ofType: "css") else {
            fatalError("Gopher page stylesheet (\(cssName)) could not be located")
        }
        
        let styles: String
        do {
            styles = try String(contentsOfFile: cssPath, encoding: .utf8)
        } catch {
            fatalError("Gopher page stylesheet (\(cssName)) could not be loaded")
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
        
        return "<html><head><style>" + styles + "</style></head><body>" + contentHtml + "</body></html>"
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
