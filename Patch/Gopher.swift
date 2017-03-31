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
                // Write the welcome string...
                let requestData = Data(base64Encoded: "DQo=", options: NSData.Base64DecodingOptions())
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
    var parts: [GopherResponsePart] = []
    var error: GopherResponseError?
    
    var html: String {
        let cssPath = Bundle.main.path(forResource: "GopherPageStyle", ofType: "css")
        guard let resolvedCssPath = cssPath else {
            fatalError("Gopher page stylesheet could not be located")
        }
        return "<html><head><link href=\"file://\(resolvedCssPath)\" rel=\"stylesheet\"></head><body>" + parts.map({
            $0.html
        }).joined() + "</body></html>"
    }
    
    let lineSeparator = String(bytes: [13, 10], encoding: String.Encoding.ascii)!
    let terminatingSequence = [".", ""]
    
    init?(data: Data) {
        guard let body = String(data: data, encoding: .utf8) else {
            self.error = .Encoding
            return nil
        }
        
        self.body = body
        self.parse()
    }
    
    private func parse() {
        let allParts = body.components(separatedBy: lineSeparator)
        
        let completeResponse = allParts.suffix(2).elementsEqual(terminatingSequence)
        if completeResponse == false {
            self.error = .Incomplete
            return
        }
        
        parts = allParts.dropLast(2).map {
            return GopherResponsePart(string: $0)
        }
    }
    
}

class GopherResponsePart {
    
    let type: Character
    let content: String
    let path: URL?
    
    var html: String {
        return "<p>" + content + "</p>"
    }
    
    init(string: String) {
        let parts = string.components(separatedBy: "\t")

        self.type = string[string.startIndex]
        self.content = parts[0].substring(from: string.index(string.startIndex, offsetBy: 1))
        self.path = nil
    }
}
