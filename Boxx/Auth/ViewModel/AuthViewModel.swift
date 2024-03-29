//
//  AuthViewModel.swift
//  Boxx
//
//  Created by Nikita Larin on 16.11.2023.
//

import Foundation
import PhotosUI
import SwiftUI
import Firebase
import FirebaseCore
import FirebaseFirestoreSwift
import FirebaseAuth
import FirebaseStorage


protocol AuthenticationFormProtocol{
    var formIsVolid: Bool {get}
}


@MainActor
class AuthViewModel: ObservableObject {
    
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var StatusMessage = ""
    @Published var orders: [ListingViewModel] = []
    @Published var myorder: [ListingViewModel] = []

    @Published var feedback: [Feedback] = []
    @Published var order: Order?
    @Published var user: [User] = []
    @Published var users: [User] = []

    @Published var profile: ListingViewModel?



    @Published private(set) var messages: [Message] = []
    @Published private(set) var lastMessageId: String = ""

    

    static let shared = AuthViewModel()
    private let storage = Storage.storage().reference()
    let db = Firestore.firestore()
    let messagesCollection = Firestore.firestore().collection("order")

  
    
    init() {
        self.userSession = Auth.auth().currentUser
        fetchOrder()
        usersearch()
        self.order = order
        getMessages()
        Task{
            await fetchUser()
            

            
        }
    }
    func signIn (withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            await fetchUser()
            
        } catch {
            print("БАГ, ошибка логина \(error.localizedDescription)")
            
        }
    }
    func createUser(withEmail email:String, password: String, fullname: String, login: String, imageUrl: String) async throws{
        do{
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            let user = User (id: result.user.uid, fullname: fullname, login: login, email: email, imageUrl: imageUrl)
            let encodedUser = try Firestore.Encoder().encode(user)
            try await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
            await fetchUser()
            
            
        } catch {
            print("БАГ, ошибка \(error.localizedDescription)")
        }
        
    }
    func signOut() {
        do{
            try Auth.auth().signOut() //выходбек
            self.userSession = nil
            self.currentUser = nil
        } catch {
            print("bags \(error.localizedDescription)")
        }
    }
    func fetchUser () async {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let snapshot = try? await Firestore.firestore().collection("users").document(uid).getDocument() else {return}
        self.currentUser = try? snapshot.data(as: User.self)
        
    }
    func usersearch(){
        users.removeAll()
        let db = Firestore.firestore()
        let ref = db.collection( "users")
        ref.getDocuments { snapshot, error in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    let data = document.data()
                    
                    let id = data["id"]as? String ?? ""
                    let fullname = data["fullname"]as? String ?? ""
                    let login = data["login"]as? String ?? ""
                    let email = data["email"]as? String ?? ""
                    let imageUrl = data["imageUrl"]as? String ?? ""
                    let user = User(id: id, fullname: fullname, login: login, email: email, imageUrl: imageUrl)
                    
                    self.users.append(user)
                }
            }
        }
    }


    ///ЗАКАЗЫ
    func fetchOrder(){
        orders.removeAll()
        let db = Firestore.firestore()
        let ref = db.collection( "Customers")
        ref.getDocuments { snapshot, error in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    let data = document.data()
                    let id = data["id"]as? String ?? ""
                    let ownerUid = data["ownerUid"]as? String ?? ""
                    let ownerName = data["ownerName"]as? String ?? ""
                    let imageUrl = data["imageUrl"]as? String ?? ""
                    let pricePerKillo = data["pricePerKillo"]as? String ?? ""
                    let cityFrom = data["cityFrom"]as? String ?? ""
                    let cityTo = data["cityTo"]as? String ?? ""
                    let imageUrls = data[ "imageUrls"]as? String ?? ""
                    let startdate = data[ "startdate"]as? String ?? ""
                    let order = ListingViewModel(id: id, ownerUid: ownerUid, ownerName: ownerName, imageUrl: imageUrl, pricePerKillo: pricePerKillo,cityFrom: cityFrom, cityTo: cityTo, imageUrls: imageUrls, startdate: startdate)
                    
                    self.orders.append(order)
                }
            }
        }
    }
    func myOrder(){
        myorder.removeAll()
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let db = Firestore.firestore()
        let ref = db.collection( "Customers")
        ref.getDocuments { snapshot, error in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    let data = document.data()
                    let id = data["id"]as? String ?? ""
                    let ownerUid = data["ownerUid"]as? String ?? ""
                    let ownerName = data["ownerName"]as? String ?? ""
                    let imageUrl = data["imageUrl"]as? String ?? ""
                    let pricePerKillo = data["pricePerKillo"]as? String ?? ""
                    let cityFrom = data["cityFrom"]as? String ?? ""
                    let cityTo = data["cityTo"]as? String ?? ""
                    let imageUrls = data[ "imageUrls"]as? String ?? ""
                    let startdate = data[ "startdate"]as? String ?? ""
                    let myorder = ListingViewModel(id: id, ownerUid: ownerUid, ownerName: ownerName, imageUrl: imageUrl, pricePerKillo: pricePerKillo,cityFrom: cityFrom, cityTo: cityTo, imageUrls: imageUrls, startdate: startdate)
                    ///if let ownerUid = uid {
                        self.myorder.append(myorder)
                    }
                }
            }
        
    }

    
    private func userReference(UserId:String) -> StorageReference{
        storage.child("user").child(UserId)
    }

    func saveImage (data: Data, UserId: String) async throws -> (name:String, path: String){
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        let path = "\(UUID().uuidString).jpeg"
        let returnedMetaData = try await userReference(UserId:UserId).child(path).putDataAsync(data, metadata: meta)
        guard let returnedPath = returnedMetaData.path, let returnedName = returnedMetaData.name else {
            throw URLError (.badServerResponse)
        }
        return (returnedName, returnedPath)
        
    }
    func saveProfileImage(item: PhotosPickerItem) {
        guard let UserId = Auth.auth().currentUser?.uid else {return}
        Task {
            guard let data = try await item.loadTransferable(type: Data.self) else {return}
                   let (path,name) = try await AuthViewModel.shared.saveImage (data: data, UserId: UserId)
            print ("SUCCESS!")
            print (path)
            print (name)
            do {
                let storageRef = Storage.storage().reference(withPath: (name))
                let url = try await storageRef.downloadURL()
                print (url)

                try await  Firestore.firestore().collection("users").document(UserId).updateData([
                    "imageUrl": url.absoluteString
                   ])

               } catch {
                   print("bags \(error.localizedDescription)")

                }
            }

    }
    func saveImage (image: UIImage, UserId: String) async throws -> (name:String, path: String){
        guard let data = image.jpegData (compressionQuality: 1) else {
            throw URLError (.backgroundSessionWasDisconnected)
        }
        
         return try await saveImage (data:data, UserId: UserId)
    }
    func getData (UserId: String, path: String) async throws -> Data {
        try await userReference (UserId: UserId).child(path).data (maxSize: 3 * 1024 * 1024)
        
    }

    // MAKR Post Feedback
    func uploadFeedback() async{

    }
    func getFeedback() {
        guard (Auth.auth().currentUser?.uid) != nil else {return}
            feedback.removeAll()
            let db = Firestore.firestore()
            let ref = db.collection( "feedback")
            ref.getDocuments { snapshot, error in
                guard error == nil else {
                    print(error!.localizedDescription)
                    return
                }
                if let snapshot = snapshot {
                    for document in snapshot.documents {
                        let data = document.data()
                        let id = data["id"]as? String ?? ""
                        let UserLogin = data["UserLogin"]as? String ?? ""
                        let text = data["text"]as? String ?? ""
                        let rating = data["rating"]as? String ?? ""
                        let imageUrl = data["imageUrl"]as? String ?? ""
                        let imageUrls = data["imageUrls"]as? String ?? ""    
                        let feedback = Feedback(id: id, UserLogin: UserLogin, text: text, rating: rating, imageUrl: imageUrl, imageUrls: imageUrls)
                        
                        self.feedback.append(feedback)
                    }
                }
            }
        }
    //MARK: Create order
    
    private func orderReference(UserId:String) -> StorageReference{
        storage.child("order").child(UserId)
    }
    func saveOrderImage (data: Data, UserId: String) async throws -> (name:String, path: String){
       
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        let path = "\(UUID().uuidString).jpeg"
        let returnedMetaData = try await orderReference(UserId:UserId).child(path).putDataAsync(data, metadata: meta)
        guard let returnedPath = returnedMetaData.path, let returnedName = returnedMetaData.name else {
            throw URLError (.badServerResponse)
        }
        return (returnedName, returnedPath)
        
    }
    func saveOrderImage(item: PhotosPickerItem) {
        guard let UserId = Auth.auth().currentUser?.uid else {return}
        Task {
            guard let data = try await item.loadTransferable(type: Data.self) else {return}
                   let (path,name) = try await AuthViewModel.shared.saveOrderImage (data: data, UserId: UserId)
            print ("SUCCESS!")
            print (path)
            print (name)
            do {
                let storageRef = Storage.storage().reference(withPath: (name))
                let url = try await storageRef.downloadURL()
                print (url)
                try await  Firestore.firestore().collection("orderimg").document(UserId).setData([
                    "orderimageUrl": url.absoluteString,
                    "UserId": UserId
                   ])
                
               } catch {
                   print("bags \(error.localizedDescription)")

                }
            }
    }

    func createOrder(senderName: String, senderUid: String,ownerUid: String,  ownerName: String, description: String, value: String, cityFrom: String, cityTo: String, imageUrls: String, recipient: String, ownerImageUrl: String,text: String) async {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        do{
            let order = Order (senderName: senderName, ownerName: ownerName, senderUid: senderUid, ownerUid: ownerUid, description:description, value:value, cityFrom: cityFrom,  cityTo:cityTo, imageUrls: imageUrls, recipient: recipient, ownerImageUrl: ownerImageUrl, text: text, timestamp: Timestamp())
            let encodedUser = try Firestore.Encoder().encode(order)
            try await Firestore.firestore().collection("order").document(uid).setData(encodedUser)
             await fetchP2Porder()

        } catch {
            print("БАГ, ошибка \(error.localizedDescription)")
        }
    }
    func fetchP2Porder () async{
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let snapshot = try? await Firestore.firestore().collection("order").document(uid).getDocument() else {return}
        self.order = try? snapshot.data(as: Order.self)
    }
    func getMessages() {
        db.collection("messages").addSnapshotListener { querySnapshot, error in
            // If we don't have documents, exit the function
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(String(describing: error))")
                return
            }
            
            // Mapping through the documents
            self.messages = documents.compactMap { document -> Message? in
                do {
                    // Converting each document into the Message model
                    // Note that data(as:) is a function available only in FirebaseFirestoreSwift package - remember to import it at the top
                    return try document.data(as: Message.self)
                } catch {
                    // If we run into an error, print the error in the console
                    print("Error decoding document into Message: \(error)")

                    // Return nil if we run into an error - but the compactMap will not include it in the final array
                    return nil
                }
            }
            
            // Sorting the messages by sent date
            self.messages.sort { $0.timestamp < $1.timestamp }
            
            // Getting the ID of the last message so we automatically scroll to it in ContentView
            if let id = self.messages.last?.id {
                self.lastMessageId = id
            }
        }
    }
    
    // Add a message in Firestore
    func createNewOrder(senderName: String, senderUid: String,ownerUid: String,  ownerName: String, description: String, value: String, cityFrom: String, cityTo: String, imageUrls: String, recipient: String, ownerImageUrl: String,text: String) {
     
            let orderCollection = Firestore.firestore().collection("order")
        guard (Auth.auth().currentUser?.uid) != nil else {return}
            
            let currentUserRef = orderCollection.document(ownerUid).collection(senderUid).document()
            let chatPartnerRef = orderCollection.document(senderUid).collection(ownerUid)
            let orderId = currentUserRef.documentID
            let neworder = Order(senderName: senderName, ownerName: ownerName, senderUid: senderUid, ownerUid: ownerUid, description:description, value:value, cityFrom: cityFrom,  cityTo:cityTo, imageUrls: imageUrls, recipient: recipient, ownerImageUrl: ownerImageUrl, text: text, timestamp: Timestamp())
            guard let messageData = try? Firestore.Encoder().encode(neworder) else {return}
            
            currentUserRef.setData((messageData))
            chatPartnerRef.document(orderId).setData(messageData)
    }

    func observeOrder(chatPartner: User, completion: @escaping ([Order]) -> Void){
         guard let uid = Auth.auth().currentUser?.uid else {return}
        _ = chatPartner.id
      let query = messagesCollection
          .document(uid)
          .collection(uid)
          .order (by: "timestamp", descending: false)
      query.addSnapshotListener { snapshot, _ in
          guard let changes = snapshot?.documentChanges.filter({ $0.type == .added}) else {return}
          let order = changes.compactMap({ try? $0.document.data(as: Order.self) })
          for (_, order) in order.enumerated() where order.ownerUid != uid {
          }
          completion(order)
          }
    }
   //  func sendMessage(_ text: String, toUser user: User) {
    //      guard let uid = Auth.auth().currentUser?.uid else { return }
    //   let chatPartnerId = user.id
    //   let currentUserRef = messagesCollection.document (uid).collection(chatPartnerId).document()
    //   let chatPartnerRef = messagesCollection .document (chatPartnerId) .collection(uid)
    //   let id = currentUserRef.documentID
    //   let message = NewOrder(
    //      senderUid:uid,
    //      ownerUid: chatPartnerId,
    //      text: text,
    //      timestamp: Timestamp()
    //)
    //   guard let messageData = try? Firestore.Encoder ().encode (message) else {return}
    //   currentUserRef.setData(messageData)
    //   chatPartnerRef.document(id).setData(messageData)
    //}
}
