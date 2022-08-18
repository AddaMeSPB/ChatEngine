import Vapor
import Fluent
import VaporRouting
import AddaSharedModels
import BSON

public func conversationsHandler(
    request: Request,
    route: ConversationsRoute
) async throws -> AsyncResponseEncodable {
    switch route {
    case .create(input: let input):
        if request.loggedIn == false { throw Abort(.unauthorized) }
        
        let content = input
        let currentUserID = request.payload.userId
        let conversation = Conversation(title: content.title, type: content.type)
        
        guard let currentUser = try await User.query(on: request.db)
                .filter(\.$id == currentUserID)
                .first().get()
            else {
                throw Abort(.notFound, reason: "Cant find admin user from id: \(currentUserID)")
            }
        
        
        guard
            let opponentUser = try await User.query(on: request.db)
                .filter(\.$phoneNumber == content.opponentPhoneNumber)
                .first().get(),
            currentUser.phoneNumber != opponentUser.phoneNumber
            else {
                throw Abort(.notFound, reason: "Cant find member user by phoneNumber: \(content.opponentPhoneNumber) or current user and member user cant be same")
            }
        
        let userConversation = try await UserConversation.query(on: request.db)
                .filter(\.$admin.$id == currentUserID)
                .join(Conversation.self, on: \UserConversation.$conversation.$id == \Conversation.$id)
                .filter(Conversation.self, \Conversation.$type == .oneToOne)
                .with(\.$conversation)
                .all().get()
        
        if userConversation.count > 0 {

            guard let uconversation = userConversation.last,
                  let conversationID = uconversation.conversation.id
            else {
                throw Abort(.notFound, reason: "Cant find admin user from id: \(currentUserID)")
            }
            
            let conversationOldResponse =  try await Conversation.query(on: request.db)
              .with(\.$admins) {
                  $0.with(\.$attachments)
              }
              .with(\.$members) {
                  $0.with(\.$attachments)
              }
              .with(\.$messages) { // this must be remove
                $0.with(\.$sender)
                  {
                      $0.with(\.$attachments)
                  }
                  .with(\.$recipient)
                  {
                      $0.with(\.$attachments)
                  }
              }
              .filter(\.$id == conversationID)
              .first()
              .unwrap(or: Abort(.notFound, reason: "Conversation not found by id \(conversationID)"))
              .get()
            
            guard let conversationID = conversationOldResponse.id
            else {
                throw Abort(.notFound, reason: "Cant find conversationID: \(conversationOldResponse.id)")
            }
            
            let admins = conversationOldResponse.$admins.value?.map { $0.response }
            let members = conversationOldResponse.$members.value?.map { $0.response }
            
            let title = members?.last?.fullName
            
            return ConversationOutPut(
                id: conversationID,
                title: title ?? "",
                type: conversation.type,
                admins: admins,
                members: members,
                lastMessage: conversationOldResponse.messages
                    .sorted(by: {$0.createdAt!.timeIntervalSince1970 < $1.createdAt!.timeIntervalSince1970})
                    .map { $0.response }.last,
                createdAt: conversation.createdAt,
                updatedAt: conversation.deletedAt,
                deletedAt: conversation.deletedAt
            )

        }
        
        _ = try await conversation.save(on: request.db)
        _ = try await conversation.$admins.attach(currentUser, method: .ifNotExists, on: request.db)
        _ = try await conversation.$members.attach(currentUser, method: .ifNotExists, on: request.db)
        _ = try await conversation.$members.attach(opponentUser, method: .ifNotExists, on: request.db)
        
        let conversationResponse = try await Conversation.query(on: request.db)
          .with(\.$admins) {
              $0.with(\.$attachments)
          }
          .with(\.$members) {
              $0.with(\.$attachments)
          }
          .with(\.$messages) {
            $0.with(\.$sender)
              {
                  $0.with(\.$attachments)
              }
              .with(\.$recipient)
              {
                  $0.with(\.$attachments)
              }
          }
          .filter(\.$id == conversation.id!)
          .first()
          .unwrap(or: Abort(.notFound, reason: "Conversation not found by id \(conversation.id!)"))
          .get()
        
        let admins = conversationResponse.$admins.value?.map { $0.response }
        let members = conversationResponse.$members.value?.map { $0.response }
        
        let title = members?.last?.fullName
        
        return ConversationOutPut(
            id: conversation.id!,
            title: title ?? "",
            type: conversation.type,
            admins: admins,
            members: members,
            lastMessage: conversation.messages
                .sorted(by: {$0.createdAt!.timeIntervalSince1970 < $1.createdAt!.timeIntervalSince1970})
                .map { $0.response }.last,
            createdAt: conversation.createdAt,
            updatedAt: conversation.deletedAt,
            deletedAt: conversation.deletedAt
        )

    case .list:
        if request.loggedIn == false { throw Abort(.unauthorized) }
        let currentUserID = request.payload.userId
        
        let page =  try await UserConversation.query(on: request.db)
          .with(\.$member)
          .with(\.$conversation) {
              $0.with(\.$admins) {
                  $0.with(\.$attachments)
              }
              $0.with(\.$members) {
                  $0.with(\.$attachments)
              }
              $0.with(\.$messages) {
                $0.with(\.$sender) { $0.with(\.$attachments) }
                $0.with(\.$recipient) { $0.with(\.$attachments) }
            }
          }
          .filter( \.$member.$id == currentUserID)
          .paginate(for: request)
          .get()
          
         return page.map { userConversation -> ConversationOutPut in
              let conversation = userConversation.conversation
              let adminsResponse = conversation.admins.map { $0.response }
              let membersResponse = conversation.members.map { $0.response } // .filter { $0.id == id }
             let messageLastResponse = conversation.messages.sorted(by: {$0.createdAt!.timeIntervalSince1970 < $1.createdAt!.timeIntervalSince1970}).map { $0.response }.last
              
              return ConversationOutPut(
                  id: conversation.id!,
                  title: userConversation.title(currentId: currentUserID),
                  type: conversation.type,
                  admins: adminsResponse,
                  members: membersResponse,
                  lastMessage: messageLastResponse,
                  createdAt: conversation.createdAt!,
                  updatedAt: conversation.updatedAt!
              )
          }

    case let .conversation(id: id, route: conversationRoute):
        return try await conversationHandler(
            request: request,
            conversationId: id,
            route: conversationRoute
        )
    case let .update(input: input):
        if request.loggedIn == false { throw Abort(.unauthorized) }
        
        let conversationDecode = input
        
        let id = conversationDecode.id
        
        guard let admins = conversationDecode.admins else {
            throw Abort(.notFound, reason: "This Conversation dont have admins, conversastion \(id)")
        }
        
        if !admins.map({ $0.id }).contains(request.payload.userId)
        {
            throw Abort(.notFound,reason: "Dont have permission to change this Conversation")
        }
        
        // only owner can update
        let conversation =  try await Conversation.query(on: request.db)
          .filter(\.$id == id)
          .first()
          .unwrap(or: Abort(.notFound, reason: "No Conversation. found! by id: \(id)"))
          .get()
          
        conversation.id = conversation.id
        conversation._$id.exists = true
        try await conversation.update(on: request.db)
        return conversation

    case let .delete(id: conversationId):
        if request.loggedIn == false { throw Abort(.unauthorized) }
        
        guard let id = ObjectId(conversationId) else {
          throw Abort(.notFound, reason: "No Conversation. found! for delete by id")
        }
        
        let conversation = try await Conversation.find(id, on: request.db)
          .unwrap(or: Abort(.notFound, reason: "No Conversation. found! by id: \(id)"))
          .get()
          
        if conversation.admins.map({ $0.id }).contains(request.payload.userId) != false {
          throw Abort(.unauthorized)
        } else {
          try await conversation.delete(on: request.db)
        }
          
        return HTTPStatus.ok
    }
}

