//
//  GopherResponsePart.swift
//  Patch
//
//  Created by Jacob Budin on 4/8/17.
//  Copyright © 2017 Jacob Budin. All rights reserved.
//

import Foundation

class GopherResponsePart {
    
    let type: Character
    let content: String
    let url: URL?
    
    var html: String {
        if type == "0" || type == "1" { // file or directory
            return "<p><a href=\"\(url!.absoluteString)\">" + content + "</a></p>"
        }
        else if type == "g" || type == "I" { // GIF or image
            return "<p><a href=\"\(url!.absoluteString)\">Image: " + content + "</a></p>"
        }
        
        return "<p>" + content + "</p>"
    }
    
    init(string: String) {
        let parts = string.components(separatedBy: "\t")
        
        self.type = string[string.startIndex]
        self.content = String(parts[0][string.index(string.startIndex, offsetBy: 1)...])
        
        if parts.count >= 3 {
            self.url = URL(string: "gopher://" + parts[2] + parts[1])
        }
        else {
            self.url = nil
        }
    }
}
