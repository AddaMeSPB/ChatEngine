@testable import App
import XCTVapor
import XCTest
import VaporRouting
import AddaSharedModels
import FluentMongoDriver
import Fluent

class MessageTests: AppTests {
    var user: UserOutput {
        var u = UserOutput.withNumber
        u.id = ObjectId("62fcd868006527c5fb64f3cb")
        return u
    }
    
    var input = MessageItem(
        conversationId: ObjectId("62fcd96687904794466e8469")!,
        messageBody: "I will ping you soon 🔜 101",
        messageType: .text,
        isRead: true,
        isDelivered: true
    )
    
    var messageID: String = ""
    var conversationID: String = "62fcd96687904794466e8469"
    var opponentuser: User!, thrdUser: User!

//    override func setUp() {
//        app = try! Application.testable()
//    }
//
//    override func tearDown() {
//        app.shutdown()
//    }

    func testConversationMessageCreate() throws {
        input.sender = user
        app.mount(siteRouter) { req, route in
            switch route {
            case .chatEngine(
                .conversations(
                    .conversation(
                        id: self.conversationID,
                        route: .messages(
                            .create(input: self.input)
                        )
                    )
                )
            ):
                return self.input
            default:
                return Response(status: .badRequest)
            }
        }
        
        try app.customTest(
            .POST,
            token: token,
            path: "v1/conversations/\(conversationID)/messages",
            beforeRequest: { req in
                try req.content.encode(input)
            }, afterResponse: { response in
                XCTAssertEqual(response.status, .ok)
                let message = try response.content.decode(MessageItem.self)
                XCTAssertNotNil(message.id)
                messageID = message.id!.hexString
                XCTAssertEqual(message.messageBody, "I will ping you soon 🔜 101")
            }
        )
    }
    
//    func testConversationMessageList() throws {
//        app.mount(siteRouter) { req, route in
//            switch route {
//            case .conversationEngine(.conversations(.conversation(id: "5fabcd48f4271d1963025d4f", route: .messages(.list)))):
//                return ""
//            default:
//                return Response(status: .badRequest)
//            }
//        }
//
//        try app.customTest(
//            .GET,
//            "v1/conversations/5fabcd48f4271d1963025d4f/messages",
//            afterResponse: { response in
//
//                let messageItems = try response.content.decode(MessagePage.self)
//                XCTAssertEqual(response.status, .ok)
//                XCTAssertEqual(messageItems.metadata.total, 73)
//
//        })
//
//    }
    
    func testConversationMessageFind() throws {
        app.mount(siteRouter) { req, route in
            switch route {
            case .chatEngine(
                .conversations(
                    .conversation(
                        id: self.conversationID,
                        route: .messages(
                            .find(id: self.messageID, route: .find)
                        )
                    )
                )
            ):
                return ""
            default:
                return Response(status: .badRequest)
            }
        }
        
        try app.customTest(
            .GET,
            token: token,
            path: "v1/conversations/5fabcd48f4271d1963025d4f/messages/60fad9bdb14a1dc66e77d72a",
            afterResponse: { response in
                let messageItem = try response.content.decode(MessageItem.self)
                XCTAssertEqual(response.status, .ok)
                XCTAssertEqual(messageItem.messageBody, "I will ping you soon 🔜 ")
            }
        )
        
    }
    
//    func testConversationMessageUpdate() throws {
//        var user = UserOutput.withNumber
//        user.id = ObjectId("5fabb1ebaa5f5774ccfe48c3")
//        user.phoneNumber = "+79218821217"
//
//        let input = MessageItem(
//            id: ObjectId("60fad9bdb14a1dc66e77d72a"),
//            conversationId: ObjectId("5fabcd48f4271d1963025d4f")!,
//            messageBody: "I will ping you soon 🔜 101",
//            messageType: .text,
//            isRead: true,
//            isDelivered: true,
//            sender: user
//        )
//
//        app.mount(siteRouter) { req, route in
//            switch route {
//            case .conversationEngine(
//                .conversations(
//                    .conversation(
//                        id: "5fabcd48f4271d1963025d4f",
//                        route: .messages(
//                            .update(route: .update(input: input))
//                        )
//                    )
//                )
//            ):
//                return input
//            default:
//                return Response(status: .badRequest)
//            }
//        }
//
//        try app.customTest(
//            .PUT,
//            "v1/conversations/5fabcd48f4271d1963025d4f/messages",
//            beforeRequest: { req in
//                var user = UserOutput.withNumber
//                user.id = ObjectId("5fabb1ebaa5f5774ccfe48c3")
//                user.phoneNumber = "+79218821217"
//
//                let input = MessageItem(
//                    conversationId: ObjectId("5fabcd48f4271d1963025d4f")!,
//                    messageBody: "I will ping you soon 🔜 101",
//                    messageType: .text,
//                    isRead: true,
//                    isDelivered: true,
//                    sender: user
//                )
//                try req.content.encode(input)
//            },
//
//            afterResponse: { response in
//
//                let messageItem = try response.content.decode(MessageItem.self)
//                XCTAssertEqual(response.status, .ok)
//                XCTAssertEqual(messageItem.messageBody, "I will ping you soon 🔜 100")
//
//        })
//
//    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

//    func testBaseURL() throws {
//        var user = UserOutput.withNumber
//        user.id = ObjectId("5fabb1ebaa5f5774ccfe48c3")
//        user.phoneNumber = "+79218821217"
//
//        let input = MessageItem(
//            id: ObjectId("60fad9bdb14a1dc66e77d72a"),
//            conversationId: ObjectId("5fabcd48f4271d1963025d4f")!,
//            messageBody: "I will ping you soon 🔜 101",
//            messageType: .text,
//            isRead: true,
//            isDelivered: true,
//            sender: user
//        )
//
//      XCTAssertEqual(
//        "http://10.0.1.2:6060/v1/conversations/5fabcd48f4271d1963025d4f/messages",
//        URLRequest(
//          data:
//            try siteRouter
//            .baseURL("http://10.0.1.2:6060")
//            .print(
//                .conversationEngine(
//                    .conversations(
//                        .conversation(
//                            id: "5fabcd48f4271d1963025d4f",
//                            route: .messages(
//                                .update(route: .update(input: input))
//                            )
//                        )
//                    )
//                )
//            )
//        )?.url?.absoluteString
//      )
//    }
    
}
