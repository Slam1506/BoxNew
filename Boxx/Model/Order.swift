//
//  Order.swift
//  Boxx
//
//  Created by Nikita Larin on 19.12.2023.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct Order: Identifiable, Codable, Hashable{
    @DocumentID var orderId: String?
    let senderName: String
    let ownerName: String
    let senderUid: String
    let ownerUid: String
    let description: String
    let value: String
    let cityFrom: String
    let cityTo: String
    let imageUrls: String
    let recipient: String
    let ownerImageUrl: String
    let text: String
    let timestamp: Timestamp

    
    var id: String {
        return orderId ?? NSUUID().uuidString
    }
    var chatPartnerId: String {
        return senderUid == Auth.auth().currentUser?.uid ? senderUid: ownerUid}

    var isFromCurrentUser: Bool {
        return senderUid == senderUid
    }
}
