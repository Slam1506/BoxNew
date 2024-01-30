//
//  Message.swift
//  Boxx
//
//  Created by Nikita Larin on 13.12.2023.
//


import Foundation

struct Message: Identifiable, Codable {
    var id: String
    var text: String
    var received: Bool
    var timestamp: Date
}
