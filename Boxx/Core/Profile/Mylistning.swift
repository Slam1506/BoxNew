//
//  Mylistning.swift
//  Boxx
//
//  Created by Nikita Larin on 05.01.2024.
//

import SwiftUI
import Firebase
@available(iOS 17.0, *)

struct Mylistning: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @available(iOS 17.0, *)
    var body: some View {
                ScrollView{
                    
                    ForEach(viewModel.orders) { item in
                        ListingitemView(item: item)}
                    .frame(height: 160)
                }.onAppear{
                    viewModel.fetchOrder()
                }
            }
}
