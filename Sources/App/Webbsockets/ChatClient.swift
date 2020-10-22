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
    
    func send(_ message: Message.Item, _ req: Request) {
        guard req.loggedIn != false else {
            logger.error("\(#line) Unauthorized send message")
            return
        }

        let messageCreate = Message(message, senderId: req.payload.userId, receipientId: nil)
        
        req.db.withConnection { _ in
            messageCreate.save(on: req.db)
        }.whenComplete { [self] res in
            
            let success: Bool
            
            switch res {
            case .failure(let err):
                self.logger.report(error: err)
                success = false
                
            case .success:
                self.logger.info("success true")
                success = true
            }
            
            messageCreate.isDelivered = success
            messageCreate.update(on: req.db)
            
            Message.query(on: req.db)
                .with(\.$sender)
                .with(\.$recipient)
                .filter(\.$id == messageCreate.id!)
                .first()
                .unwrap(or: Abort(.notFound, reason: "No Message found! by id: \(id)"))
                .map { original in
                    let message = ChatOutGoingEvent.message(original.response).jsonString
                    let lastMessage = ChatOutGoingEvent.conversation(original.response).jsonString
                    logger.info("\(#line): \(message)")
                    
                    
                    
                    self.socket.send(message ?? "")
                    self.socket.send(lastMessage ?? "")
                    
//                    if let msgJsonString = original.response.jsonString {
//                        logger.info("\(#line): \(original)")
//                    }
                }
            
        }
    }

    static func == (lhs: ChatClient, rhs: ChatClient) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

