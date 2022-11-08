//
//  GopherResponse.swift
//  Patch
//
//  Created by Jacob Budin on 4/8/17.
//  Copyright © 2017 Jacob Budin. All rights reserved.
//

import Foundation

class GopherResponse {
    
    let text: String?
    let data: Data?
    var error: GopherResponseError?
    let lineSeparator = String(bytes: [13, 10], encoding: String.Encoding.ascii)!
    
    var isText: Bool { text != nil }
    var isBinary: Bool { data != nil }
    
    var isDirectory: Bool {
        guard let text = text else {
            return false
        }
        
        if text.contains("\n\n") {
            return false
        }
        
        let parts = text.components(separatedBy: lineSeparator)
        
        for part in parts.dropLast() {
            // if there's an empty line, this cannot be a directory listing
            if part.isEmpty {
                return false
            }
        }
        
        return true
    }
    
    init(data: Data) {
        guard let text = String(data: data, encoding: .utf8) else {
            self.data = data
            self.text = nil
            return
        }
        
        self.text = text
        self.data = nil
    }
    
}
