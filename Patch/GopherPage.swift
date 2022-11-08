//
//  GopherPage.swift
//  Patch
//
//  Created by Jacob Budin on 4/8/17.
//  Copyright © 2017 Jacob Budin. All rights reserved.
//

import Foundation
import ReactiveSwift
import Swime

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
        var contentType: String
        
        if (self.status.value == GopherStatus.Failed) {
            print("Showing error...")
            contentHtml = "Could not load \(self.request!.url)"
            contentType = "error"
        }
        else if (self.response?.isBinary)! {
            print("Showing binary...")
            contentHtml = parseBinary()
            contentType = "image"
        }
        else if (self.response?.isDirectory)! {
            print("Showing directory...")
            contentHtml = parseDirectory().map({
                $0.html
            }).joined()
            contentType = "directory"
        }
        else {
            print("Showing file...")
            contentHtml = parsePlain()
            contentType = "text"
        }
        
        return "<html><head><style>" + styles + "</style></head><body class=\"type-" + contentType + "\">" + contentHtml + "</body></html>"
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
        
        do {
            try request.load() {
                (data) in
                self.status.value = .Loaded
                self.response = GopherResponse(data: data)
                self.status.value = .Parsed
            }
        } catch {
            self.status.value = .Failed
        }
    }
    
    private func parseBinary() -> String {
        guard let data = self.response?.data else {
            return ""
        }
        let mimeType = Swime.mimeType(data: data)
        let encodedData = data.base64EncodedString()
        switch mimeType?.type {
            case .gif?, .jpg?, .png?, .webp?:
                guard let mime = mimeType?.mime else {
                    return ""
                }
                return "<img src=\"data:" + mime + ";base64," + encodedData + "\">"
            default:
                return ""
        }
    }
    
    private func parsePlain() -> String {
        guard let body = self.response?.text else {
            return ""
        }
        
        let html = body.components(separatedBy: "\n\n").map({
            "<p>" + $0 + "</p>"
        }).joined()
        
        return html
    }
    
    private func parseDirectory() -> [GopherResponsePart] {
        guard let parts = self.response?.text?.components(separatedBy: lineSeparator) else {
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
