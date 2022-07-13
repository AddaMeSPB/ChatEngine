
@testable import XCTVapor
@testable import App
import AddaSharedModels

extension Application {
  static func testable() throws -> Application {
      let app = Application(.testing)
      try configure(app)
      try app.autoRevert().wait()
      try app.autoMigrate().wait()
      return app
  }
}

extension XCTApplicationTester {
  @discardableResult
  public func customTest(
    _ method: HTTPMethod,
    _ path: String,
    headers: HTTPHeaders = [:],
    body: ByteBuffer? = nil,
    file: StaticString = #file,
    line: UInt = #line,
    beforeRequest: (inout XCTHTTPRequest) throws -> () = { _ in },
    afterResponse: (XCTHTTPResponse) throws -> () = { _ in }
  ) throws -> XCTApplicationTester {
    var request = XCTHTTPRequest(
      method: method,
      url: .init(path: path),
      headers: headers,
      body: body ?? ByteBufferAllocator().buffer(capacity: 0)
    )
      
    request.headers.bearerAuthorization = BearerAuthorization(token: token)
    
    try beforeRequest(&request)

    do {
      let response = try performTest(request: request)
      try afterResponse(response)
    } catch {
      XCTFail("\(error)", file: (file), line: line)
      throw error
    }
    return self
  }
}

let token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGF0dXMiOjAsImV4cCI6MTY2NTY1MDk4MCwiaWF0IjoxNjU3MDk3MzgwLCJ1c2VySWQiOiI1ZmFiYjFlYmFhNWY1Nzc0Y2NmZTQ4YzMiLCJwaG9uZU51bWJlciI6Iis3OTIxODgyMTIxNyJ9.sb4INDZSqtkU7CpXniE_pwVWsi4lRQZadUKBlRO6hk5LXM0paFpXZsw5QdgR9Chs05XSlwLzfC-TiFE3LEBX1VJP6X7GdPrRvMrHN26ejbceJbCTJlThfsVC0mBMEbwu583L5ZjKkXr2GA6BBGsfUC2xkskykZ9phG7kZ7-GtBwZMjsCh0dGGUGFAMKAjWqkfIiFUToHXfZmsG5mr1evBo02_ow2Pm_ymw_wUlKUC0bMzi-Ew9JV3uO00_f21TKhgFe-OyT6tetLiedafyOVNiZI5UyDRVgLHXW7YgppvYy6p663j6j14uTkcblL9cfnCCILg2tfITDRBoiv2k2X6w"

public struct BearerAuthorization {
    /// The plaintext token
    public let token: String

    /// Create a new `BearerAuthorization`
    public init(token: String) {
        self.token = token
    }
}

extension HTTPHeaders {
    /// Access or set the `Authorization: Bearer: ...` header.
    public var bearerAuthorization: BearerAuthorization? {
        get {
            guard let string = self.first(name: .authorization) else {
                return nil
            }

            let headerParts = string.split(separator: " ")
            guard headerParts.count == 2 else {
                return nil
            }
            guard headerParts[0].lowercased() == "bearer" else {
                return nil
            }
            return .init(token: String(headerParts[1]))
        }
        set {
            if let bearer = newValue {
                replaceOrAdd(name: .authorization, value: "Bearer \(bearer.token)")
            } else {
                remove(name: .authorization)
            }
        }
    }
}

//public struct CreateConversation: Codable, Equatable {
//  public init(title: String, type: ConversationType, opponentPhoneNumber: String) {
//    self.title = title
//    self.type = type
//    self.opponentPhoneNumber = opponentPhoneNumber
//  }
//
//  public let title: String
//  public let type: ConversationType
//  public let opponentPhoneNumber: String
//}
