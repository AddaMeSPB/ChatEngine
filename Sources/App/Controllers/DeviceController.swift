//
//  File.swift
//  
//
//  Created by Saroar Khandoker on 29.11.2020.
//

import Vapor
import Fluent
import MongoKitten
import FluentMongoDriver
import JWT
import AddaAPIGatewayModels

extension DeviceController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.post(use: createOrUpdate)
  }
}

final class DeviceController {
  private func createOrUpdate(_ req: Request) throws -> EventLoopFuture<Device.RequestResponse> {
    if req.loggedIn == false { throw Abort(.unauthorized) }
    
    let content = try req.content.decode(Device.RequestResponse.self)
     let data = Device(name: content.name, model: content.model, osVersion: content.osVersion, token: content.token, voipToken: content.voipToken, userId: content.ownerId)
    
    return Device.query(on: req.db)
      .filter(\.$token == content.token)
      .filter(\.$voipToken == content.voipToken)
      .first()
      .flatMap { device in
        
        guard let device = device else {
          return data.save(on: req.db).map {
            return data.res
          }
        }

        return req.eventLoop.makeSucceededFuture(device.res)

      }
  }
  
}
