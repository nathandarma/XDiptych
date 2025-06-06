//
//  Item.swift
//  XDiptych
//
//  Created by Nathan Darma on 7/6/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
