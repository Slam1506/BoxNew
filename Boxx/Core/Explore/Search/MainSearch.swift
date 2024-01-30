//
//  MainSearch.swift
//  Boxx
//
//  Created by Nikita Larin on 16.11.2023.
//

import SwiftUI
@available(iOS 17.0, *)
struct MainSearch: View {
    @State private  var showDestinationSearchView = false
    @EnvironmentObject var viewModel: AuthViewModel
    let user: User


    
    var body: some View {
        NavigationStack{
            if showDestinationSearchView{
                DestinationSearchView (show: $showDestinationSearchView)
            } else{
                ScrollView{
                    LazyVStack(spacing: 5){
                        SearchAndFilter()
                            .onTapGesture {
                                withAnimation{
                                    showDestinationSearchView.toggle()
                                }
                            }
                        ForEach(viewModel.orders) {item in NavigationLink(value: item){ ListingitemView(item: item)}
                    }
                    .frame(height: 160)
                }
                }  .navigationDestination(for: ListingViewModel.self){ item in
                    ListingDetail(item: item)
                        .navigationBarBackButtonHidden()
                        
            }.onAppear{
                viewModel.fetchOrder()
            }
        }
      
        }
    }
}


