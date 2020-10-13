//
//  WebSocketClient.swift
//  
//
//  Created by Alif on 19/6/20.
//

import Vapor
import MongoKitten

open class WebSocketClient {
    open var id: ObjectId
    open var socket: WebSocket

    public init(id: ObjectId, socket: WebSocket) {
        self.id = id
        self.socket = socket
    }
}
