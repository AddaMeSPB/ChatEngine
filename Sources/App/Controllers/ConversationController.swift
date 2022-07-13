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
import AddaSharedModels

extension ConversationController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.post("", use: createOrFind)
    routes.post(":conversationsId", "users", ":usersId", use: addUserToConversation)
    routes.get(use: readAll) // "users", ":users_id",
    routes.get(":conversationsId", use: find)
    routes.get(":conversationsId", "messages", use: readAllMessageByCoversationID)
    routes.put(use: update)
    routes.delete(":conversationsId", use: delete)
  }
}

final class ConversationController {
    
    func createOrFind(_ req: Request) async throws -> Conversation {
        if req.loggedIn == false { throw Abort(.unauthorized) }
        
        let content = try req.content.decode(CreateConversation.self)
        let currentUserID = req.payload.userId
        let conversation = Conversation(title: content.title, type: content.type)
        
        guard
            let member = try await User.query(on: req.db)
                .filter(\.$phoneNumber == content.opponentPhoneNumber)
                .first().get(),
            let memberID = member.id else {
                throw Abort(.notFound, reason: "Cant find member user")
            }
        
        let userConversation = try await UserConversation.query(on: req.db)
                .filter(\.$member.$id ~~ [currentUserID, memberID])
                .join(Conversation.self, on: \UserConversation.$conversation.$id == \Conversation.$id)
                .filter(Conversation.self, \Conversation.$type == .oneToOne)
                .with(\.$conversation)
                .all().get()
        
        if userConversation.count > 0 {
           return userConversation.last!.conversation
        }
        
        try await conversation.save(on: req.db).get()
        try await conversation.$members.attach(member, method: .ifNotExists, on: req.db).get()
        
        guard let currentUser = try await User.query(on: req.db)
                .filter(\.$id == currentUserID)
                .first().get()
            else {
                throw Abort(.notFound, reason: "Cant find user admin from id: \(currentUserID)")
            }
        
        try await conversation.$members.attach(currentUser, method: .ifNotExists, on: req.db).get()
        
        return conversation

    }
  
    func readAll(_ req: Request) async throws -> Page<ConversationWithKids> {
      
      if req.loggedIn == false { throw Abort(.unauthorized) }
      let currentUserID = req.payload.userId
      
      let page =  try await UserConversation.query(on: req.db)
        .filter(\.$member.$id == currentUserID)
        .with(\.$conversation) {
          $0.with(\.$admins)
          $0.with(\.$members)
          $0.with(\.$messages) {
            $0.with(\.$sender)
              .with(\.$recipient)
          }
        }
        .paginate(for: req)
        .get()
        
        return page.map { userConversation in
            let conversation = userConversation.conversation
            let adminsResponse = conversation.admins.map { $0 }
            let membersResponse = conversation.members.map { $0 } // .filter { $0.id == id }
            let messageLastResponse = conversation.messages.sorted(by: {
                $0.createdAt!.timeIntervalSince1970 < $1.createdAt!.timeIntervalSince1970
            }).map { $0.response }.last
            
            return ConversationWithKids(
              id: conversation.id,
              title: conversation.title,
              type: conversation.type,
              admins: adminsResponse,
              members: membersResponse,
              lastMessage: messageLastResponse,
              createdAt: conversation.createdAt!,
              updatedAt: conversation.updatedAt!
            )
        }
    }
  
  private func find(_ req: Request) async throws -> Conversation {
    if req.loggedIn == false { throw Abort(.unauthorized) }
    guard let _id = req.parameters.get("\(Conversation.schema)Id"), let id = ObjectId(_id) else {
        throw Abort(.notFound, reason: "\(Conversation.schema)Id not found" )
    }
    
    return try await Conversation.query(on: req.db)
      .with(\.$admins).with(\.$members)
      .filter(\.$id == id)
      .first()
      .unwrap(or: Abort(.notFound, reason: "Conversation not found by id \(Conversation.schema)Id") )
      .get()
    
  }
  
  private func readAllMessageByCoversationID(_ req: Request) async throws -> Page<Message.Item> {
    
    if req.loggedIn == false {
      throw Abort(.unauthorized)
    }
    
    guard
        let _id = req.parameters.get("\(Conversation.schema)Id"),
        let id = ObjectId(_id)
    else {
        throw Abort(.notFound, reason: "\(Conversation.schema)Id not found" )
    }
    
    return try await Message.query(on: req.db)
      .with(\.$sender)
      .with(\.$recipient)
      .filter(\.$conversation.$id == id)
      .sort(\.$createdAt, .descending)
      .paginate(for: req)
      .map { (originalMessage: Page<Message>) -> Page<Message.Item> in
        originalMessage.map { $0.response }
      }
      .get()
  }
  
  func addUserToConversation(_ req: Request) throws -> EventLoopFuture<Conversation> {
    
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
    
    return conversationQuery.and(userQuery)
      .flatMap { conversation, user in
        conversation.$members.attach(
          user, method: .ifNotExists, on: req.db
        ).map {
          conversation
        }
    }
    
  }
  
  private func update(_ req: Request) async throws -> Conversation {
    if req.loggedIn == false {
      throw Abort(.unauthorized)
    }
    
    let conversationDecode = try req.content.decode(Conversation.self)
    
    guard let id = conversationDecode.id else {
       throw Abort(.notFound, reason: "Conversation id missing")
    }
    
    if !conversationDecode.admins.map({ $0.id }).contains(req.payload.userId) {
        throw Abort(.notFound,reason: "Dont have permission to change this Conversation")
    }
    
    // only owner can delete
    let conversation =  try await Conversation.query(on: req.db)
      .filter(\.$id == id)
      .first()
      .unwrap(or: Abort(.notFound, reason: "No Conversation. found! by id: \(id)"))
      .get()
      
    conversation.id = conversation.id
    conversation._$id.exists = true
    try await conversation.update(on: req.db)
    return conversation
  }
  
  private func delete(_ req: Request) async throws -> HTTPStatus {
    if req.loggedIn == false {
      throw Abort(.unauthorized)
    }
    
    guard
      let _id = req.parameters.get("\(Conversation.schema)_id"),
      let id = ObjectId(_id)
    else {
      throw Abort(.notFound, reason: "No Conversation. found! for delete by id")
    }
    
    return try await Conversation.find(id, on: req.db)
      .unwrap(or: Abort(.notFound, reason: "No Conversation. found! by id: \(id)"))
      .flatMapThrowing { conversation in
        if conversation.admins.map({ $0.id }).contains(req.payload.userId) != false {
          throw Abort(.notFound,reason: "Dont have permission to change this Conversation")
        } else {
           _ = conversation.delete(on: req.db)
        }
      }.map { .ok }.get()
    
  }
}
