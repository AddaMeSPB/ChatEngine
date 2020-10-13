//
//  WebsocketClients.swift
//  
//
//  Created by Alif on 19/6/20.
//

import Vapor
import MongoKitten
import AddaAPIGatewayModels

final class WebsocketClients {
    
    let lock: Lock
    var eventLoop: EventLoop
    var allCliendts: [ObjectId: WebSocketClient]
    let logger: Logger
    
    var activeClients: [WebSocketClient] {
        self.lock.withLock {
            self.allCliendts.values.filter { !$0.socket.isClosed }
        }
    }
    
    init(eventLoop: EventLoop, clients: [ObjectId: WebSocketClient] = [:]) {
        self.eventLoop = eventLoop
        self.allCliendts = clients
        self.logger = Logger(label: "WebsocketClients")
        self.lock = Lock()
    }
    
    func add(_ client: WebSocketClient) {
        self.lock.withLock {
            self.allCliendts[client.id] = client
        }
    }
    
    func remove(_ client: WebSocketClient) {
        self.lock.withLock {
            self.allCliendts[client.id] = nil
        }
    }
    
    func find(_ objectId: ObjectId) -> WebSocketClient? {
        self.lock.withLock {
            return self.allCliendts[objectId]
        }
    }
    
    func send(_ msg: ChatMessage, req: Request) {
        let chatClients = self.activeClients.compactMap { $0 as? ChatClient }
        
        for client in chatClients where client.id != msg.sender!.id {
            client.send(msg, req)
        }
    }
    
    deinit {
        let futures = self.allCliendts.values.map { $0.socket.close() }
        try! self.eventLoop.flatten(futures).wait()
    }
    
}
