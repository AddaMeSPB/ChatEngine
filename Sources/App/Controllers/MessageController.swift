//
//  MessageController.swift
//  
//
//  Created by Saroar Khandoker on 02.10.2020.
//

import Vapor
import Fluent
import MongoKitten
import FluentMongoDriver
import JWT
import AddaAPIGatewayModels

extension MessageController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(":messages_id", use: readAllMessagesByConversationID)
        routes.put(use: update)
        routes.delete(":messages_id", use: delete)
    }
}

final class MessageController {
    private func readAllMessagesByConversationID(_ req: Request) throws -> EventLoopFuture<Page<Message.Item>> {
        
        if req.loggedIn == false {
            throw Abort(.unauthorized)
        }
        
        guard let _id = req.parameters.get("\(Conversation.schema)_id"), let id = ObjectId(_id) else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "\(Conversation.schema)_id not found" ) )
        }

        return Message.query(on: req.db)
            .with(\.$sender)
            .with(\.$recipient)
            .filter(\.$conversation.$id == id)
            .sort(\.$createdAt, .ascending)
            .paginate(for: req)
            .map { (original: Page<Message>) -> Page<Message.Item> in
                original.map { $0.response }
            }
        
        //        return Event.query(on: req.db)
        //            .sort(\.$createdAt, .descending)
        //            .paginate(for: req)
        //            .map { (original: Page<Event>) -> Page<Event.Res> in
        //                original.map { $0.response }
        //            }
        
    }
    
    func update(_ req: Request) throws -> EventLoopFuture<Message.Item> {
        
        if req.loggedIn == false { throw Abort(.unauthorized) }
        let message = try req.content.decode(Message.self)
        
        guard let id = message.id else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "Message id missing"))
        }
        
        return Message.query(on: req.db)
            .filter(\.$id == id)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No Message found! by id: \(id)"))
            .flatMap { msg in
                msg.id = message.id
                msg._$id.exists = true
                return msg.update(on: req.db).map { msg.response }
            }
    }
    
    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        
        if req.loggedIn == false { throw Abort(.unauthorized) }
        
        guard let _id = req.parameters.get("\(Message.schema)_id"), let id = ObjectId(_id) else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound))
        }
        
        return Message.query(on: req.db)
            .filter(\.$id == id)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No Message found! by id: \(id)"))
            .flatMap { $0.delete(on: req.db) }
            .map { .ok }
    }
}

