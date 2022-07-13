@testable import App
import Fluent
import AddaSharedModels
import FluentMongoDriver

extension User {
    static func create(
        phoneNumber: String,
        firstName: String,
        database: Database
    ) throws -> User {
        let user = User(phoneNumber: phoneNumber, firstName: firstName)
        try user.save(on: database).wait()
        return user
    }
}

extension UserConversation {
    static func create(
        member: User,
        admin: User,
        conversation: Conversation,
        database: Database
    ) throws -> UserConversation {
        let userConveration = try UserConversation(id: ObjectId(), member: member, admin: admin, conversation: conversation)
        try userConveration.save(on: database).wait()
        return userConveration
    }
}

extension Conversation {
    static func create(
        title: String,
        type: ConversationType,
        member: User,
        admin: User,
        database: Database
    ) throws -> Conversation {
        
        let conversation = Conversation(title: title, type: type)
        try conversation.save(on: database).wait()
        
        _ = try UserConversation.create(member: member, admin: admin, conversation: conversation, database: database)
        
        return conversation
    }
}
