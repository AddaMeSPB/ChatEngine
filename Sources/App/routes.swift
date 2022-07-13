import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "ChatEngine still working!"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }

    try app.group("v1") { api in
        
        let messages = api.grouped("messages")
        let messagesAuth = messages.grouped(JWTMiddleware())
        try messagesAuth.register(collection: MessageController() )
        
        let conversations = api.grouped("conversations")
        let conversationsAuth = conversations.grouped(JWTMiddleware())
        try conversationsAuth.register(collection: ConversationController())
        
        let chat = api.grouped("chat")
        let chatAuth = chat.grouped(JWTMiddleware())
        let webSocketController = WebSocketController(eventLoop: app.eventLoopGroup.next(), db: app.db)
        try chatAuth.register(collection: ChatController(wsController: webSocketController) )
       
    }
}
