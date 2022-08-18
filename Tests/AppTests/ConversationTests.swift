//
//  ConversationTests.swift
//  
//
//  Created by Saroar Khandoker on 06.07.2022.
//

@testable import App
import XCTVapor
import XCTest
import VaporRouting
import AddaSharedModels
import FluentMongoDriver
import Fluent
import Foundation

final class ConversationTests: AppTests {

    var conversationCreate: ConversationCreate = .init(title: "Friday night with bicycle with 11 people", type: .oneToOne, opponentPhoneNumber: "+79218821211")
    var conversastionId: String = "62fcd96687904794466e8469"
    var opponentPhoneNumber = "+79218821211"
    var adminMobileNumber = "+79218821211"
    
//    override func setUp() {
//        app = try! createTestApp()
//        try! lgoin()
//    }
//
//    override func tearDown() {
//        app.shutdown()
//    }
    
    func testPostConversation() async throws {
        app = try! createTestApp()
        
        _ = try await User.create(phoneNumber: opponentPhoneNumber, firstName: "opponentPhoneNumber", database: app.db)
        
        app.mount(siteRouter) { req, route in
            switch route {
            case .chatEngine(
                .conversations(
                    .create(input: .init(title: "Friday night with bicycle with 12 people", type: .group, opponentPhoneNumber: self.opponentPhoneNumber))
                )
            ):
                return ConversationCreate(title: "Friday night with bicycle with 11 people", type: .group, opponentPhoneNumber: self.opponentPhoneNumber)
            default:
                return Response(status: .badRequest)
            }
        }
        
        try app.customTest(
            .POST,
            token: token,
            path: "v1/conversations",
            beforeRequest: { req in
                try req.content.encode(ConversationCreate(title: "Friday night with bicycle with 12 people", type: .oneToOne, opponentPhoneNumber: opponentPhoneNumber))
            }, afterResponse: { response in
                XCTAssertEqual(response.status, .ok)
                let conversation = try response.content.decode(Conversation.self)
                self.conversastionId  = conversation.id!.hexString
                XCTAssertNotNil(conversation.id)
                XCTAssertEqual(conversation.title, "Friday night with bicycle with 12 people")
            }
        )
        
        _ = try await User.delete(phoneNumber: opponentPhoneNumber, database: app.db)
    }
    
    func testFindConversation() throws {
        app.mount(siteRouter) { req, route in
            switch route {
            case .chatEngine(
                .conversations(
                    .conversation(id: self.conversastionId, route: .find)
                )
            ):
                
                return "findConversation"
            default:
                return Response(status: .badRequest)
            }
        }
        
        try app.customTest(.GET,token: token, path: "v1/conversations/\(conversastionId)", afterResponse:  { response in
            XCTAssertEqual(response.status, .ok)
            let conversation = try response.content.decode(ConversationOutPut.self)
            XCTAssertNotNil(conversation.id)
            XCTAssertEqual(conversation.title, "VaporRouteing")
        })
    }

    func testCreateConversationMessage() throws {
        app.mount(siteRouter) { req, route in
            switch route {
            case .chatEngine(
                .conversations(
                    .conversation(
                        id: self.conversastionId,
                        route: .messages(
                            .create(
                                input: MessageItem(
                                    conversationId: ObjectId(self.conversastionId)!,
                                    messageBody: "Hello!",
                                    messageType: .text
                                )
                            )
                        )
                    )
                )
            ):
                
                return MessageItem(
                    conversationId: ObjectId(self.conversastionId)!,
                    messageBody: "Hello!",
                    messageType: .text
                )
            default:
                return Response(status: .badRequest)
            }
        }
        
        try app.customTest(
            .POST,
            token: token,
            path: "v1/conversations/\(conversastionId)/messages",
            beforeRequest: { req in
                try req.content.encode(MessageItem(
                    conversationId: ObjectId(self.conversastionId)!,
                    messageBody: "Hello!",
                    messageType: .text
                ))
            }, afterResponse: { response in
                XCTAssertEqual(response.status, .ok)
                let message = try response.content.decode(MessageItem.self)
                XCTAssertNotNil(message.id)
                XCTAssertEqual(message.messageBody, "Hello!")
            }
        )
    }
    
    func testListConversation() throws {
        app = try! createTestApp()
        
        app.mount(siteRouter) { req, route in
            switch route {
            case .chatEngine(
                .conversations(.list(query: .init()))
            ): return "findConversation"
            default:
                return Response(status: .badRequest)
            }
        }
        
        try app.customTest(.GET, token: token, path: "v1/conversations", afterResponse:  { response in
            XCTAssertEqual(response.status, .ok)
            let conversations = try response.content.decode(ConversationsResponse.self)
            XCTAssertNotNil(conversations.items.last?.title)
        })
    }
    
    func testDeleteConversation() throws  {
        app.mount(siteRouter) { req, route in
            switch route {
            case .chatEngine(
                .conversations(.delete(id: self.conversastionId))
            ):
                
                return "findConversation"
            default:
                return Response(status: .badRequest)
            }
        }
    }

}
