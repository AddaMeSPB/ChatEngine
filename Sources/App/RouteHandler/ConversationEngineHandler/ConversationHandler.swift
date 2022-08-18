import Vapor
import Fluent
import VaporRouting
import AddaSharedModels
import BSON

public func conversationHandler(
    request: Request,
    conversationId: String,
    originalConversation: ConversationOutPut? = nil,
    route: ConversationRoute
) async throws -> AsyncResponseEncodable {
    switch route {
    case .find:
        if request.loggedIn == false { throw Abort(.unauthorized) }
        guard let id = ObjectId(conversationId) else {
            throw Abort(.notFound, reason: "\(Conversation.schema)Id not found" )
        }
        
        return try await Conversation.query(on: request.db)
          .with(\.$admins).with(\.$members)
          .filter(\.$id == id)
          .first()
          .unwrap(or: Abort(.notFound, reason: "Conversation not found by id \(Conversation.schema)Id") )
          .get()
        
    case .addUser(let userID):
        if request.loggedIn == false { throw Abort(.unauthorized) }
        guard let conversationID = ObjectId(conversationId) else {
            throw Abort(.notFound, reason: "\(Conversation.schema)Id not found" )
        }
        
        guard let userID = ObjectId(userID) else {
            throw Abort(.notFound, reason: "\(Conversation.schema)Id not found" )
        }
        
        
        let conversation = try await Conversation.find(conversationID, on: request.db)
             .unwrap(or: Abort(.notFound, reason: "Cant find conversation") )
             .get()
           
        let user = try await User.find(userID, on: request.db)
             .unwrap(or: Abort(.notFound, reason: "Cant find user") )
             .get()
        
        _ = try await conversation.$members.attach(user, method: .ifNotExists, on: request.db)
        
        return AddUser(conversationsId: conversationID, usersId: userID)

    case .messages(let messagesRoute):
        return try await messagesHandler(
            request: request,
            conversationId: conversationId,
            route: messagesRoute
        )        
    }
}

extension AddUser: Content {}
