//
//  ConversationTests.swift
//  
//
//  Created by Saroar Khandoker on 06.07.2022.
//

@testable import App
import XCTVapor
import AddaSharedModels
import FluentMongoDriver
import Fluent

class ConversationTests: XCTestCase {
    let user = User(phoneNumber: "+79218821217", firstName: "Alif")
    let user1 = User(phoneNumber: "+79218821218", firstName: "Alla")
    let user2 = User(phoneNumber: "+79218821219", firstName: "Masum")
    let payload = Payload(id: ObjectId(), phoneNumber: "+79218821217")
    let title = "Alla"
    let conversationsURI = "/v1/conversations"
    var app: Application!
    
    var opponentuser: User!, thrdUser: User!

    override func setUp() {
        app = try! Application.testable()
        opponentuser = try? User.create(phoneNumber: "+79218821218", firstName: "Alla", database: app.db)
        thrdUser = try? User.create(phoneNumber: "+79218821219", firstName: "Masum", database: app.db)
    }

    override func tearDown() {
        app.shutdown()
    }

    func testConversationCanBeSavedWithAPI() throws {
        let conversation = CreateConversation(title: "Alla", type: .oneToOne, opponentPhoneNumber: opponentuser.phoneNumber)
        try app.customTest(.POST, conversationsURI, beforeRequest: { request in
        _  = try request.content.encode(conversation)
        }, afterResponse: { response in
            let receivedConversation = try response.content.decode(ConversationResponse.Item.self)
              XCTAssertEqual(receivedConversation.title, title)
              XCTAssertNotNil(receivedConversation.id)

            try app.customTest(.GET, "\(conversationsURI)/\(receivedConversation.id)", afterResponse: { response in
                let conversationRes = try response.content.decode(ConversationResponse.Item.self)
                XCTAssertEqual(conversationRes.title, title)
                XCTAssertEqual(conversationRes.id, receivedConversation.id)
            })
        })
        
        sleep(3)
        try app.customTest(.POST, conversationsURI, beforeRequest: { request in
        _  = try request.content.encode(conversation)
        }, afterResponse: { response in
            let receivedConversation = try response.content.decode(ConversationResponse.Item.self)
              XCTAssertEqual(receivedConversation.title, title)
              XCTAssertNotNil(receivedConversation.id)

            try app.customTest(.GET, "\(conversationsURI)/\(receivedConversation.id)", afterResponse: { response in
                let conversationRes = try response.content.decode(ConversationResponse.Item.self)
                XCTAssertEqual(conversationRes.title, title)
                XCTAssertEqual(conversationRes.id, receivedConversation.id)
            })
        })
        
        sleep(3)
        let conversation2 = CreateConversation(title: "Masum", type: .oneToOne, opponentPhoneNumber: thrdUser.phoneNumber)
        try app.customTest(.POST, conversationsURI, beforeRequest: { request in
        _  = try request.content.encode(conversation2)
        }, afterResponse: { response in
            let receivedConversation = try response.content.decode(ConversationResponse.Item.self)
              XCTAssertEqual(receivedConversation.title, "Masum")
              XCTAssertNotNil(receivedConversation.id)

            try app.customTest(.GET, "\(conversationsURI)?page=1&par=30", afterResponse: { response in
                let conversationRes = try response.content.decode(ConversationResponse.self)
                XCTAssertEqual(conversationRes.items[0].title, "Masum")
                XCTAssertEqual(conversationRes.items.count, 2)
            })
        })
        
        defer {
            _ = opponentuser.delete(on: app.db)
            _ = thrdUser.delete(on: app.db)
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

//
//There are a number of ways to do it. The easiest it to probably create a custom signer for tests,
//inject that in to your app in your test configuration and then create a JWT in your test
//case you can send to authenticate the request


//        "access": {
//                "accessToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGF0dXMiOjAsImV4cCI6MTY2NTY1MDk4MCwiaWF0IjoxNjU3MDk3MzgwLCJ1c2VySWQiOiI1ZmFiYjFlYmFhNWY1Nzc0Y2NmZTQ4YzMiLCJwaG9uZU51bWJlciI6Iis3OTIxODgyMTIxNyJ9.sb4INDZSqtkU7CpXniE_pwVWsi4lRQZadUKBlRO6hk5LXM0paFpXZsw5QdgR9Chs05XSlwLzfC-TiFE3LEBX1VJP6X7GdPrRvMrHN26ejbceJbCTJlThfsVC0mBMEbwu583L5ZjKkXr2GA6BBGsfUC2xkskykZ9phG7kZ7-GtBwZMjsCh0dGGUGFAMKAjWqkfIiFUToHXfZmsG5mr1evBo02_ow2Pm_ymw_wUlKUC0bMzi-Ew9JV3uO00_f21TKhgFe-OyT6tetLiedafyOVNiZI5UyDRVgLHXW7YgppvYy6p663j6j14uTkcblL9cfnCCILg2tfITDRBoiv2k2X6w",
//                "refreshToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjVmYWJiMWViYWE1ZjU3NzRjY2ZlNDhjMyIsImlhdCI6MTY1NzA5NzM4MCwiZXhwIjoxNjg4NjMzMzgwfQ.YsI99_MqDkJArP6iq-hN7zfLpLU82uoYkzSnc73EOq22m0PDMy872O8IuqxjdX12WWw0ImbBYzUZ_jbiTZwssmMC_0hzE3nvI5Hp3b9YbtPrjHEcfNQsDGdcCdb8u7vxe5RABu5-MumVC78cDjvMMqaB14uUNS7D_MMtEL69vpv5lbHZyjv3imGrSfF066n-l61QsIYsPH84pdRDAttM8YeeUTiMzwIeDFynAiEJJVcKjQ47vDKGWaG2HSp0UECagDyPNote4hGRRvWua6tGhDjxULupynKkrmfxRhoibVQcTgEA0-o3VSg3yWvjx0RhZWRgbDpQ2Cw7ota4iuxFeA"
//            }

public struct Metadata: Codable, Equatable {
  public let per, total, page: Int

  public init(per: Int, total: Int, page: Int) {
    self.per = per
    self.total = total
    self.page = page
  }
}

public struct ConversationResponse: Codable {
  public let items: [Item]
  public let metadata: Metadata

  public init(items: [Item], metadata: Metadata) {
    self.items = items
    self.metadata = metadata
  }

  public struct Item: Codable {
    public init(
      id: String, title: String, type: ConversationType,
      members: [User], admins: [User],
      createdAt: Date, updatedAt: Date
    ) {
      self.id = id
      self.title = title
      self.type = type
      self.members = members
      self.admins = admins
      self.createdAt = createdAt
      self.updatedAt = updatedAt
    }

    public let id, title: String
    public var type: ConversationType
    public let members: [User]?
    public let admins: [User]?

    public let createdAt, updatedAt: Date
  }
}
