import Fluent
import Vapor
import VaporRouting
import AddaSharedModels
import BSON

func routes(_ app: Application) throws {
    app.get { req in
        return "ChatEngine still working!"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }

    try app.group("v1") { api in
        
        let chat = api.grouped("chat")
        let chatAuth = chat.grouped(JWTMiddleware())
        let webSocketController = WebSocketController(eventLoop: app.eventLoopGroup.next(), db: app.db)
        try chatAuth.register(collection: ChatController(wsController: webSocketController) )
       
    }
}

public func siteHandler(
    request: Request,
    route: SiteRoute
) async throws -> AsyncResponseEncodable {
    switch route {
    case .eventEngine:
        return Response(status: .badRequest)
    case let .chatEngine(chatEngineRoute):
        return try await chatEngineHandler(request: request, route: chatEngineRoute)
    case .authEngine:
        return Response(status: .badRequest)
    }
}
