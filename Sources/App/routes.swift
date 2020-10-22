import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }

    try app.group("v1") { api in
        let events = api.grouped("messages")
        let eventsAuth = events.grouped(JWTMiddleware())
        try eventsAuth.register(collection: MessageController() )
        
        let conversations = api.grouped("conversations")
        let conversationsAuth = conversations.grouped(JWTMiddleware())
        try conversationsAuth.register(collection: ConversationController())
        
        let chat = api.grouped("chat")
        let chatAuth = chat.grouped(JWTMiddleware())
        let webSocketController = WebSocketController(eventLoop: app.eventLoopGroup.next(), db: app.db)
        try chatAuth.register(collection: ChatController(wsController: webSocketController) )
        
    }
}
