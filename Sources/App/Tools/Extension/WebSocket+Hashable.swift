//
//  WebSocket+Hashable.swift
//  
//
//  Created by Saroar Khandoker on 30.09.2020.
//

import Vapor
import MongoKitten

extension WebSocket: Hashable {
    public static func == (lhs: WebSocket, rhs: WebSocket) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
