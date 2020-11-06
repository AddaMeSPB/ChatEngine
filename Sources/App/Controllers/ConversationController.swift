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
    routes.post(":conversationsId", "users", ":usersId", use: addUserToConversation)
    routes.get(use: readAll) // "users", ":users_id",
    routes.get(":conversationsId", "messages", use: readAllMessageByCoversationID)
    routes.put(use: update)
    routes.delete(":conversationsId", use: delete)
  }
}

final class ConversationController {
  
  func readAll(_ req: Request) throws -> EventLoopFuture<Page<ConversationWithKids>> {
    
    if req.loggedIn == false { throw Abort(.unauthorized) }

    return UserConversation.query(on: req.db)
      .filter(\.$member.$id == req.payload.userId)
      .with(\.$conversation) {
        $0.with(\.$admins)
        $0.with(\.$members)
        $0.with(\.$messages) {
          $0.with(\.$sender).with(\.$recipient)
        }
      }
      .paginate(for: req)
      .map { (userConversations: Page<UserConversation>) -> Page<ConversationWithKids> in
        userConversations.map { userConversation in
          let conversation = userConversation.conversation
          let adminsResponse = conversation.admins.map { $0 }
          let membersResponse = conversation.members.map { $0 } // .filter { $0.id == id }
          let messageLastResponse = conversation.messages.sorted(by: { $0.createdAt!.timeIntervalSince1970 < $1.createdAt!.timeIntervalSince1970 })
            .map { $0.response }.last
          
          return ConversationWithKids(
            id: conversation.id,
            title: conversation.title,
            admins: adminsResponse,
            members: membersResponse,
            lastMessage: messageLastResponse,
            createdAt: conversation.createdAt!,
            updatedAt: conversation.updatedAt!
          )
          
        }
      }
  }
  
  private func readAllMessageByCoversationID(_ req: Request) throws -> EventLoopFuture<Page<Message.Item>> {
    
    if req.loggedIn == false {
      throw Abort(.unauthorized)
    }
    
    guard let _id = req.parameters.get("\(Conversation.schema)Id"), let id = ObjectId(_id) else {
      return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "\(Conversation.schema)Id not found" ) )
    }
    
    return Message.query(on: req.db)
      .with(\.$sender)
      .with(\.$recipient)
      .filter(\.$conversation.$id == id)
      .sort(\.$createdAt, .descending)
      .paginate(for: req)
      .map { (originalMessage: Page<Message>) -> Page<Message.Item> in
        originalMessage.map { $0.response }
      }
  }
  
  func addUserToConversation(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
    
    guard let _idC = req.parameters
            .get("\(Conversation.schema)Id"),
          let conversationID = ObjectId(_idC),
          let _idU = req.parameters
            .get("\(User.schema)Id"),
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
      conversation.$members.attach(user, method: .ifNotExists, on: req.db).transform(to: .created)
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
