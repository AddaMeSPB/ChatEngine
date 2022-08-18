import Vapor
import VaporRouting
import AddaSharedModels


public func chatEngineHandler(
    request: Request,
    route: ChatEngineRoute
) async throws -> AsyncResponseEncodable {
    switch route {
    case let .conversations(conversationsRoute):
        return try await conversationsHandler(request: request, route: conversationsRoute)
    case let .messages(messagesRoute):
        return try await messagesHandler(request: request, conversationId: "", route: messagesRoute)
    }
}
