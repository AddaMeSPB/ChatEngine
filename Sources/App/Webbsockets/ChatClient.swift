//
//  ChatClient.swift
//  
//
//  Created by Saroar Khandoker on 30.09.2020.
//

import Vapor
import MongoKitten
import Fluent
import AddaAPIGatewayModels
import APNS

final class ChatClient: WebSocketClient, Hashable {

    let logger: Logger = Logger(label: "ChatClient")
    
    
    override init(id: ObjectId, socket: WebSocket) {
        super.init(id: id, socket: socket)
    }

    func send(_ event: ChatOutGoingEvent) {
        guard let text = event.jsonString else {
            logger.error("Error occer when convert ChatOutGoingEvent to jsonString")
            return
        }

        socket.send(text)
    }
    
    func send(_ message: Message, _ req: Request) {
        guard req.loggedIn != false else {
            logger.error("\(#line) Unauthorized send message")
            return
        }

        Message.query(on: req.db)
            .with(\.$sender)
            .with(\.$recipient)
            .filter(\.$id == message.id!)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No Message found! by id: \(id)"))
            .map { original in
                let message = ChatOutGoingEvent.message(original.response).jsonString
                let lastMessage = ChatOutGoingEvent.conversation(original.response).jsonString

                self.socket.send(message ?? "")
                self.socket.send(lastMessage ?? "")
              
            }
      
    }

    static func == (lhs: ChatClient, rhs: ChatClient) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
