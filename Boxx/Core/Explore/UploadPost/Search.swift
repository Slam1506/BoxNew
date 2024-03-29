//
//  Search.swift
//  Boxx
//
//  Created by Nikita Larin on 17.11.2023.
//

import SwiftUI
import Firebase

enum SearchOptions{
    case dates
    case killo
    case location
    case price
}
struct dataType : Identifiable {
    
    var id : String
    var name : String
    var reg : String
}


struct Search: View {
    
    @ObservedObject var data = getData()
    var body: some View {
        NavigationView{
                    
                    ZStack(alignment: .top){
                        
                        GeometryReader{_ in
                            
                            // Home View....
                     
                            
                        }.background(Color(.systemGray6).edgesIgnoringSafeArea(.all))
                        
                        CustomSearchBar(data: self.$data.datas).padding(.top, 20)
                        
                    }.navigationTitle("Вы уезжате?")

                    .navigationBarHidden(false)
                }
            }
        }

        struct Search_Previews: PreviewProvider {
            static var previews: some View {
                Search()
            }
        }

        struct CustomSearchBar : View {
            
            @State var txt = ""
            @Binding var data : [dataType]
            
            var body : some View{
                
                VStack(spacing: 0){
                    
                    HStack{
                        Image(systemName: "magnifyingglass")
                        TextField("Откуда выезжате?", text: self.$txt)
                            .font(.footnote)
                            .fontWeight(.semibold )
                        Image(systemName:"line.3.horizontal.decrease.circle")

                        
                        if self.txt != ""{
                            
                            Button(action: {
                                
                                self.txt = ""
                                
                            }) {
                                
                                Text("Отмена")
                            }
                            .foregroundColor(.red)
                            
                        }

                    }.padding()
                    
                    if self.txt != ""{
                        
                        if  self.data.filter({$0.name.lowercased().contains(self.txt.lowercased())}).count == 0{
                            
                            Text("No Results Found").foregroundColor(Color.black.opacity(0.5)).padding()
                        }
                        else{
                            
                        List(self.data.filter{$0.name.lowercased().contains(self.txt.lowercased())}){i in
                                    
                            NavigationLink(destination: Detail(data: i)) {
                                
                                Text(i.name)
                            }
                                    
                                
                            }.frame(height: UIScreen.main.bounds.height / 2)
                        }

                    }
                    
                    
                }.background(Color.white)
                .padding()
            }
        }

        class getData : ObservableObject{
            
            @Published var datas = [dataType]()
            
            init() {
                
                let db = Firestore.firestore()
                
                db.collection("city").getDocuments { (snap, err) in
                    
                    if err != nil{
                        
                        print((err?.localizedDescription)!)
                        return
                    }
                    
                    for i in snap!.documents{
                        
                        let id = i.documentID
                        let name = i.get("name") as! String
                        let reg = i.get("reg") as! String
                        
                        self.datas.append(dataType(id: id, name: name, reg: reg))
                    }
                }
            }
        }




struct Detail : View {
    @EnvironmentObject var viewModel: AuthViewModel
    
    func UploadPostservice(freeForm: String )
    {
        guard let uid = viewModel.currentUser?.id else {return}
        let ownerUid = uid
        let ownerName = viewModel.currentUser?.login
        let imageUrl = viewModel.currentUser?.imageUrl

        
        let db = Firestore.firestore()
        db.collection("Customers").document().setData([ "id": NSUUID().uuidString,  "ownerUid": ownerUid, "ownerName": ownerName, "pricePerKillo": pricePerKillo, "cityFrom": data.name, "cityTo": cityTo, "startdate":startdate.convertToMonthYearFormat(), "imageUrls": data.reg, "imageUrl": imageUrl]) {error in
            if let error = error {
                print(error.localizedDescription)
            }
            
        }
    }
    

    var data : dataType
    @State var id = ""
    @State var ownerUid = ""
    @State var ownerName = ""
    @State var pricePerKillo = ""
    @State var cityTo = ""
    @State private var startdate = Date()

    


    
     
    @State private var selectedOption: SearchOptions = .location
    
    

    
    var body : some View{
        
        
        VStack{
            Text("Укажите дату и время отправления из города")
            Text(data.name)
                .font(.title3)
            
            VStack(alignment: .leading){
                if selectedOption == .location{
                    Text("Заметка")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack(){
                        Image(systemName: "pencil.circle")
                            .imageScale(.small)
                        TextField("Укажите что можете взять", text: $cityTo)
                            .font(.subheadline)
                    }
                    .frame(height: 60 )
                    .padding(.horizontal)
                    .overlay{RoundedRectangle(cornerRadius: 8)
                            .stroke(lineWidth: 1.0)
                            .foregroundStyle(Color(.systemGray4))
                    }
                    
                } else{
                    CollapsedPickerView(title: "Описание", description: "Написать")
                }
            } .modifier(CollapsidDestModifier())
                .frame(height: selectedOption == .location ? 120  : 64)
                .onTapGesture {
                    withAnimation(){selectedOption = .location}
                }
            
            VStack(alignment: .leading){
                if selectedOption == .price{
                    Text("Стоимость")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack(){
                        Image(systemName: "pencil.circle")
                            .imageScale(.small)
                        TextField("Укажите стоимость за кг", text: $pricePerKillo)
                            .font(.subheadline)
                    }
                    .frame(height: 60 )
                    .padding(.horizontal)
                    .overlay{RoundedRectangle(cornerRadius: 8)
                            .stroke(lineWidth: 1.0)
                            .foregroundStyle(Color(.systemGray4))
                    }
                    
                } else{
                    CollapsedPickerView(title: "Стоимость", description: "Руб")
                }
            } .modifier(CollapsidDestModifier())
                .frame(height: selectedOption == .price ? 120  : 64)
                .onTapGesture {
                    withAnimation(){selectedOption = .price}
                }
          
            VStack(alignment: .leading){
                if selectedOption == .dates {
                    Text ("Когда уезжаете?")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text ("Укажите дату")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    VStack{
                        DatePicker("Дата", selection:$startdate)
                            .datePickerStyle(.wheel)
                            .frame(maxHeight:200)
                        Divider()
                        
                    }
                    .foregroundStyle(.gray)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    
                }else {
                    CollapsedPickerView(title: "Когда", description: "Даты")
                }
            }   .modifier(CollapsidDestModifier())
                .frame(height: selectedOption == .dates ?60  : 40)
                .onTapGesture {
                    withAnimation(){selectedOption = .dates}
                }
            Spacer()
            VStack{
                Button(action : {
                    self.UploadPostservice(freeForm: self.id)
                }) {
                    Image(systemName: "arrow.right.circle")
                        .resizable()
                        .frame(width:100, height: 100 )
                        .scaledToFit()
                        .padding(.vertical, 40)
                }
            }
            
        }
        
    }
    
}


            
struct CollapsidDestModif: ViewModifier {
    func body (content: Content) -> some View {
        content
        .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()
            .shadow(radius: 10)
    }
}

struct CollapsedPicker: View {
    let title: String
    let description: String
    var body: some View {
        VStack{
            HStack{
                Text(title)
                    .foregroundStyle(.gray)
                Spacer()
                Text(description)
            }
            .fontWeight(.semibold)
            .font(.subheadline)
            
        }
    }
}

extension Date {
//2
    func convertToMonthYearFormat() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d.MM.yyyy в HH:mm"
        return dateFormatter.string(from: self)
    }
}


extension String {
//1
    func convertToDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = .current

        return dateFormatter.date(from: self)
    }
//3
    func convertToDisplayFormat() -> String {
        guard let date = self.convertToDate() else { return "N/A" }
        return date.convertToMonthYearFormat()
    }
}
