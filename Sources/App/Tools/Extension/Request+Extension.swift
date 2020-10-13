//
//  Request+Extension.swift
//  
//
//  Created by Alif on 7/6/20.
//

import Vapor
import MongoKitten

extension Request {
    public var mongoDB: MongoDatabase {
        return application.mongoDB.hopped(to: eventLoop)
    }
}
