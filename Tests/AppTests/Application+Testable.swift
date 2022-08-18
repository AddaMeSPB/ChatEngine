
@testable import XCTVapor
@testable import App
import AddaSharedModels

extension Application {
  static func createTestApp() throws -> Application {
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
    token: String? = nil,
    path: String,
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
      
      if let token = token {
          request.headers.bearerAuthorization = BearerAuthorization(token: token)
      }
    
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
            
            guard headerParts.count == 2 ,
                  headerParts[0].lowercased() == "bearer" else {
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
