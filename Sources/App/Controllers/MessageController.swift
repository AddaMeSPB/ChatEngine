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
import AddaSharedModels

extension MessageController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("by" ,"conversations" ,":conversationsId", use: readAllMessagesByConversationID)
        routes.put(use: update)
        routes.delete(":messagesId", use: delete)
    }
}

final class MessageController {
    private func readAllMessagesByConversationID(_ req: Request) async throws -> Page<Message.Item> {
        
        if req.loggedIn == false {
            throw Abort(.unauthorized)
        }
        
        guard let _id = req.parameters.get("\(Conversation.schema)Id"),
              let id = ObjectId(_id)
        else {
            throw Abort(.notFound, reason: "\(Conversation.schema)Id not found")
        }

        let page = try await Message.query(on: req.db)
            .with(\.$sender)
            .with(\.$recipient)
            .filter(\.$conversation.$id == id)
            .sort(\.$createdAt, .descending)
            .paginate(for: req)
            .get()
           
            return page.map { $0.response }
        
        //        return Event.query(on: req.db)
        //            .sort(\.$createdAt, .descending)
        //            .paginate(for: req)
        //            .map { (original: Page<Event>) -> Page<Event.Res> in
        //                original.map { $0.response }
        //            }
        
    }
    
    func update(_ req: Request) async throws -> Message.Item {
        
        if req.loggedIn == false { throw Abort(.unauthorized) }
        let message = try req.content.decode(Message.self)
        
        guard let id = message.id else {
            throw Abort(.notFound, reason: "Message id missing \(message)")
        }
        
        let item = try await Message.query(on: req.db)
            .filter(\.$id == id)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No Message found! by id: \(id)"))
            .get()
        
        item.id = message.id
        item._$id.exists = true
        try await item.update(on: req.db).get()
        return item.response
    }
    
    func delete(_ req: Request) async throws -> HTTPStatus {
        
        if req.loggedIn == false { throw Abort(.unauthorized) }
        
        guard let _id = req.parameters.get("\(Message.schema)_id"), let id = ObjectId(_id) else {
            throw Abort(.notFound, reason: "message can't delete becz id: is missing")
        }
        
        return try await Message.query(on: req.db)
            .filter(\.$id == id)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No Message found! by id: \(id)"))
            .flatMap { $0.delete(on: req.db) }
            .map { .ok }
            .get()
    }
}

