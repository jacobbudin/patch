//
//  GopherResponse.swift
//  Patch
//
//  Created by Jacob Budin on 4/8/17.
//  Copyright © 2017 Jacob Budin. All rights reserved.
//

import Foundation

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
