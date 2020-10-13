//
//  ConversationController.swift
//  
//
//  Created by Saroar Khandoker on 30.09.2020.
//

import Vapor
import Fluent
import MongoKitten
import JWT
import AddaAPIGatewayModels

extension ConversationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post(":conversations_id", use: addUser)
        routes.get(use: readAll)
        routes.get(":conversations_id", "messages", use: readAllMessageByCoversationID)
        routes.put(use: update)
        routes.delete(":conversations_id", use: delete)
    }
}

final class ConversationController {
    
    func readAll(_ req: Request) throws -> EventLoopFuture<Page<ConversationWithKids>> {
        
        if req.loggedIn == false { throw Abort(.unauthorized) }
        
//        guard let _id = req.parameters.get("\(User.schema)_id"), let id = ObjectId(_id) else {
//            return req.eventLoop
//                .makeFailedFuture(Abort(.notFound, reason: "User id is not found!"))
//        }

        return Conversation.query(on: req.db)
            .with(\.$admins)
            .with(\.$members)
            .with(\.$chatMessages)
            .sort(\.$createdAt, .descending)
            //.filter(\.$members ~~ id)
            .paginate(for: req)
            .map { (conversations: Page<Conversation>) -> Page<ConversationWithKids> in
                conversations.map { conversation in
                    // you mean here ?
                    //let filter = conversation.members.filter { $0.id  == id }
                    let adminsResponse = conversation.admins.map { $0.response }
                    let membersResponse = conversation.members.map { $0.response }
                    let messageLastResponse = conversation.chatMessages.map { $0.response }.last //have to sort to get correct result
                    return ConversationWithKids(
                        id: conversation.id,
                        title: conversation.title,
                        admins: adminsResponse,
                        members: membersResponse,
                        lastMessage: messageLastResponse
                    )

                }
            }
    }
    
    private func readAllMessageByCoversationID(_ req: Request) throws -> EventLoopFuture<Page<Message.Item>> {
        
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
            .map { (originalMessage: Page<Message>) -> Page<Message.Item> in
                originalMessage.map { $0.response }
            }
    }

    func addUser(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        
        guard let _idC = req.parameters.get("\(Conversation.schema)_id"),
              let conversationID = ObjectId(_idC),
              let _idU = req.parameters.get("\(User.schema)_id"),
              let userID = ObjectId(_idU)
        
        else {
            return req.eventLoop
                .makeFailedFuture(
                    Abort(.notFound, reason: "Conversation or User id missing")
                )
        }
        
        let conversationQuery = Conversation.find(conversationID, on: req.db)
            .unwrap(or: Abort(.notFound, reason: "Cant find conversation") )
        
        let userQuery = User.find(userID, on: req.db)
            .unwrap(or: Abort(.notFound, reason: "Cant find user") )
        
        return conversationQuery.and(userQuery).flatMap { conversation, user in
            conversation.$members.attach(user, on: req.db).transform(to: .created)
        }
    }

    private func update(_ req: Request) throws -> EventLoopFuture<Conversation> {
        if req.loggedIn == false {
            throw Abort(.unauthorized)
        }

        let conversation = try req.content.decode(Conversation.self)

        guard let id = conversation.id else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "Conversation id missing"))
        }
        
        if !conversation.admins.map({ $0.id }).contains(req.payload.userId) {
            return req.eventLoop.makeFailedFuture(
                Abort(.notFound,reason: "Dont have permission to change this Conversation")
            )
        }

        // only owner can delete
        return Conversation.query(on: req.db)
            .filter(\.$id == id)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No Conversation. found! by id: \(id)"))
            .flatMap { con in
                conversation.id = con.id
                conversation._$id.exists = true
                return conversation.update(on: req.db).map { con }

        }
    }

    private func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        if req.loggedIn == false {
            throw Abort(.unauthorized)
        }

        guard let _id = req.parameters.get("\(Conversation.schema)_id"), let id = ObjectId(_id) else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound))
        }
        
        return Conversation.find(id, on: req.db)
            .unwrap(or: Abort(.notFound, reason: "No Conversation. found! by id: \(id)"))
            .flatMapThrowing { conversation in
                if conversation.admins.map({ $0.id }).contains(req.payload.userId) != false {
                    throw Abort(.notFound,reason: "Dont have permission to change this Conversation")
                } else {
                    conversation.delete(on: req.db)
                }
            }.map { .ok }
        
    }
}
