//
//  ListingViewModel.swift
//  Boxx
//
//  Created by Nikita Larin on 16.12.2023.
//


import Foundation

struct ListingViewModel: Identifiable, Codable, Hashable{
    let id: String
    let ownerUid: String
    let ownerName: String
    let imageUrl: String
    var pricePerKillo: String
    let cityFrom: String
    let cityTo: String
    var imageUrls: String
    var startdate: String

    
}
