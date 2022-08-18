//
//  ChatHandle.swift
//  
//
//  Created by Alif on 19/6/20.
//

import Vapor
import Foundation
import MongoKitten
import AddaSharedModels

class ChatHandle {
    var chatClients: WebsocketClients
    
    init(eventLoop: EventLoop) {
        self.chatClients = WebsocketClients(eventLoop: eventLoop)
    }
    
    func connectionHandler(ws: WebSocket, req: Request) {
        
        ws.onPong { ws in
            ws.onText { (ws, text) in
                print(#line, text)
            }
        }
        
        ws.onPong { ws in
            ws.onText { (ws, text) in
                print(#line, text)
            }
        }
        
        ws.onText { [self] ws, text in
            guard let data = text.data(using: .utf8) else {
                print(#line, "Wrong encoding for received message")
                return
            }
            
            let string = String(data: data, encoding: .utf8)
            print(#line, string as Any)
            
            let chatOutGoingEvent = ChatOutGoingEvent.decode(data: data)
            
            switch chatOutGoingEvent {
            case .connect(let user):
                guard let userID = user.id else {
                    print(#line, "User id is missing")
                    return
                }
                print(#line, user)
                let client = ChatClient(id: userID, socket: ws)
                chatClients.add(client)
            case .disconnect(let user):
                guard let userID = user.id else {
                    print(#line, "User id is missing")
                    return
                }
                print(#line, user)
                let client = ChatClient(id: userID, socket: ws)
                chatClients.remove(client)
            case .message(let msg):
                print(#line, msg)
                chatClients.send(msg, req: req)
                
            case .conversation(let lastMessage):
                print(#line, lastMessage)
                chatClients.send(lastMessage, req: req)
                
            case .notice(let msg):
                print(#line, msg)
            case .error(let error):
                print(#line, error)
            case .none:
                print(#line, "decode error")
            }
            
            //            } catch {
            //                print(#line, error.localizedDescription)
            //            }
            
        }
    }
    
}

struct WebsocketMessage<T: Codable>: Codable {
    var client: UUID = UUID()
    let data: T
}

extension Data {
    func decodeWebsocketMessage<T: Codable>(_ type: T.Type) -> WebsocketMessage<T>? {
        try? JSONDecoder().decode(WebsocketMessage<T>.self, from: self)
    }
}


//"{"type":"connect","conversation":{"id":"5f78851afd41fde755669cc0","title":"Cool","creator":{"id":"5f78851afd41fde755669cc0","firstName":"Alif","phoneNumber":"+79218821218"},"members":[{"id":"5f78851afd41fde755669cc0","firstName":"Alif","phoneNumber":"+79218821218"}]}}"


//{"type":"message","message":{"id":"5f78851afd41fde755669cc0","sender":{"id":"5f78826c156076f971b25e7b","firstName":"Alif","phoneNumber":"+79218821218"},"messageBody":"Hello there","messageType":"text","conversationId":"5f78851afd41fde755669cc0","isRead":false}}


//{ "type": "connect",
//    "user": {
//        "id":"5f78851afd41fde755669cc0",
//        "title": "Testing",
//        "updated_at": "2020-10-03T14:05:14Z",
//        "creator": {
//            "_id": "5f78826c156076f971b25e7b",
//            "updated_at": "2020-10-03T13:53:48Z",
//            "phone_number": "+79218821218",
//            "created_at": "2020-10-03T13:53:48Z"
//        },
//        "members":[{
//            "_id":"5f78826c156076f971b25e7b",
//            "updated_at":"2020-10-03T13:53:48Z",
//            "phone_number":"+79218821218",
//            "created_at":"2020-10-03T13:53:48Z"
//        }],
//        "created_at":"2020-10-03T14:05:14Z"
//    }
//
//}
