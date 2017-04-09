//
//  Gopher.swift
//  Patch
//
//  Created by Jacob Budin on 3/15/17.
//  Copyright © 2017 Jacob Budin. All rights reserved.
//

import Foundation

enum GopherStatus {
    case Queued, Loading, Loaded, Parsed
}

enum GopherResponseError {
    case Encoding, Incomplete
}
