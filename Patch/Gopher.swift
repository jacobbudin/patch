//
//  Gopher.swift
//  Patch
//
//  Created by Jacob Budin on 3/15/17.
//  Copyright © 2017 Jacob Budin. All rights reserved.
//

import Foundation
import BlueSocket
import ReactiveSwift

enum GopherStatus {
    case Queued, Loading, Loaded, Parsed
}

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

class GopherRequest {
    let url: URL
    let socket: Socket
    
    
    init?(url: URL) {
        self.url = url
        do {
            self.socket = try Socket.create(family: Socket.ProtocolFamily.inet)
            try self.socket.connect(to: self.url.host!, port: 70)
        }
        catch let error {
            print(error)
            return nil
        }
    }
    
    func load(handler: @escaping (Data) -> Void) {
        let queue = DispatchQueue.global(qos: .default)
        
        // Create the run loop work item and dispatch to the default priority global queue...
        queue.async { [unowned socket] in
            
            var shouldKeepRunning = true
            
            var readData = Data(capacity: 1024000)
            
            do {
                var requestData = Data(base64Encoded: "DQo=", options: NSData.Base64DecodingOptions())
                
                if self.url.path.isEmpty == false {
                    
                    let crlf = String(bytes: [13, 10], encoding: String.Encoding.ascii)!
                    requestData = String(self.url.path.characters.dropFirst()).appending(crlf).data(using: String.Encoding.ascii)
                }
                
                try socket.write(from: requestData!)
                
                repeat {
                    let bytesRead = try socket.read(into: &readData)
                    
                    if bytesRead == 0 {
                        shouldKeepRunning = false
                        break
                    }
                    
                } while shouldKeepRunning
                
                socket.close()
                handler(readData)
            }
            catch let error {
                guard let socketError = error as? Socket.Error else {
                    print("Unexpected error by connection at \(socket.remoteHostname):\(socket.remotePort)...")
                    return
                }
            }
        }
    }
    
}

enum GopherResponseError {
    case Encoding, Incomplete
}

class GopherResponse {
    
    let body: String
    var error: GopherResponseError?
    let lineSeparator = String(bytes: [13, 10], encoding: String.Encoding.ascii)!
    
    var isDirectory: Bool {
        if self.body.contains("\n\n") {
            return false
        }
        
        let parts = self.body.components(separatedBy: lineSeparator)
        
        for part in parts.dropLast() {
            // if there's an empty line, this cannot be a directory listing
            if part.isEmpty {
                return false
            }
        }
        
        return true
    }
    
    init?(data: Data) {
        guard let body = String(data: data, encoding: .utf8) else {
            self.error = .Encoding
            return nil
        }
        
        self.body = body
    }
    
}

class GopherResponsePart {
    
    let type: Character
    let content: String
    let url: URL?
    
    var html: String {
        if type == "0" || type == "1" {
            return "<p><a href=\"\(url!.absoluteString)\">" + content + "</a></p>"
        }
        
        return "<p>" + content + "</p>"
    }
    
    init(string: String) {
        let parts = string.components(separatedBy: "\t")

        self.type = string[string.startIndex]
        self.content = parts[0].substring(from: string.index(string.startIndex, offsetBy: 1))
        
        if parts.count >= 3 {
            self.url = URL(string: "gopher://" + parts[2] + parts[1])
        }
        else {
            self.url = nil
        }
    }
}
