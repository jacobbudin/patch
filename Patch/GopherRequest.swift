//
//  GopherRequest.swift
//  Patch
//
//  Created by Jacob Budin on 4/8/17.
//  Copyright © 2017 Jacob Budin. All rights reserved.
//

import Foundation
import Socket

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
