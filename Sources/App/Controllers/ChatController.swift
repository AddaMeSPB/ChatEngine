//
//  File.swift
//  
//
//  Created by Saroar Khandoker on 19.10.2020.
//

import Vapor
import Fluent
import MongoKitten
import JWT
import AddaAPIGatewayModels

extension ChatController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.webSocket(onUpgrade: self.webSocket)
    }
}

struct ChatController {
    let wsController: WebSocketController
    
    func webSocket(_ req: Request, socket: WebSocket) {
        self.wsController.connect(socket, req: req)
    }
    
}
