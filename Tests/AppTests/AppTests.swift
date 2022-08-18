@testable import App
import XCTVapor
import AddaSharedModels

class AppTests: XCTestCase {
    
    var app: Application!
    public var token = """
    eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGF0dXMiOjAsImV4cCI6MTY3MDMzMTU1OSwiaWF0IjoxNjYxNzc3OTU5LCJ1c2VySWQiOiI1ZmFiYjFlYmFhNWY1Nzc0Y2NmZTQ4YzMiLCJwaG9uZU51bWJlciI6Iis3OTIxODgyMTIxNyJ9.OC2yQxD7clzY1Hz2AQG1peBtcTfgZUwUvVFpPbt6cDU
    """
    var verifySMSInOutput: VerifySMSInOutput = .draff
    var loginResponse: LoginResponse = .draff
    
    func createTestApp() throws -> Application {
        app = Application(.testing)
        try configure(app)
        app.databases.reinitialize()
        try app.autoRevert().wait()
        try app.autoMigrate().wait()
        return app
    }
    
//    func lgoinViaMobile() throws {
//
//        let inputOutput = VerifySMSInOutput(phoneNumber: "+79211111111")
//        try app.customTest(
//            .POST,
//            3030,
//            "/v1/auth/login",
//            beforeRequest: { req in
//                try req.content.encode(inputOutput)
//            }, afterResponse: { response in
//                XCTAssertEqual(response.status, .ok)
//                let verificationResponse = try response.content.decode(VerifySMSInOutput.self)
//                self.verifySMSInOutput = verificationResponse
//                XCTAssertNotNil(verificationResponse.attemptId)
//            }
//        )
//        
//        try app.customTest(
//            .POST,
//            3030,
//            "/v1/auth/verify_sms",
//            beforeRequest: { req in
//                try req.content.encode(self.verifySMSInOutput)
//            }, afterResponse: { response in
//                XCTAssertEqual(response.status, .ok)
//                let lgoinResponse = try response.content.decode(LoginResponse.self)
//                
//                XCTAssertNotNil(lgoinResponse.user.id)
//            }
//        )
//        
//    }
    
}
