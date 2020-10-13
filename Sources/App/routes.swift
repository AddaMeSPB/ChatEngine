import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }

    let chatHandle = ChatHandle(eventLoop: app.eventLoopGroup.next())

    try app.group("v1") { api in
        let events = api.grouped("messages")
        let eventsAuth = events.grouped(JWTMiddleware())
        try eventsAuth.register(collection: MessageController() )
        
        let conversations = api.grouped("conversations")
        let conversationsAuth = conversations.grouped(JWTMiddleware())
        try conversationsAuth.register(collection: ConversationController())
        
        let chat = api.grouped("chat")
        let chatAuth = chat.grouped(JWTMiddleware())
        chatAuth.webSocket() { req, ws in
            chatHandle.connectionHandler(ws: ws, req: req)
        }
        
    }
}
