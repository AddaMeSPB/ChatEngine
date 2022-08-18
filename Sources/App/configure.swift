import Fluent
import FluentMongoDriver
import Vapor
import APNS
import JWTKit
import VaporRouting
import AddaSharedModels

// Route
enum SiteRouterKey: StorageKey {
    typealias Value = AnyParserPrinter<URLRequestData, SiteRoute>
}

extension Application {
    var router: SiteRouterKey.Value {
        get {
            self.storage[SiteRouterKey.self]!
        }
        set {
            self.storage[SiteRouterKey.self] = newValue
        }
    }
}

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
//    guard
//        let KEY_IDENTIFIER = Environment.get("KEY_IDENTIFIER"),
//        let TEAM_IDENTIFIER = Environment.get("TEAM_IDENTIFIER") else {
//        fatalError("No value was found at the given public key environment 'APNSAuthKey'")
//    }
//    let keyIdentifier = JWKIdentifier.init(string: KEY_IDENTIFIER)
  
  switch app.environment {
  case .development:
    app.apns.configuration = try .init( authenticationMethod: .jwt(
        key: .private(pem: Data(Environment.apnsKey.utf8)),
        keyIdentifier: .init(string: Environment.apnsKeyId),
        teamIdentifier: Environment.apnsTeamId
        ),
        topic: Environment.apnsTopic,
        environment: .sandbox
    )
  case .production:
    app.apns.configuration = try .init( authenticationMethod: .jwt(
        key: .private(pem: Data(Environment.apnsKey.utf8)),
        keyIdentifier: .init(string: Environment.apnsKeyId),
        teamIdentifier: Environment.apnsTeamId
        ),
        topic: Environment.apnsTopic,
        environment: .production
    )
  default:
    break
  }
    
    app.middleware.use(JWTMiddleware())
    
    var connectionString: String = ""
    app.setupDatabaseConnections(&connectionString)

    try app.initializeMongoDB(connectionString: connectionString)
    try app.databases.use(.mongo(
        connectionString: connectionString
    ), as: .mongo)
    
    // Add HMAC with SHA-256 signer.
    let jwtSecret = Environment.get("JWT_SECRET") ?? String.random(length: 64)
    app.jwt.signers.use(.hs256(key: jwtSecret))

    // Encoder & Decoder
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    ContentConfiguration.global.use(encoder: encoder, for: .json)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    if app.environment == .production {
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.port = 6060
    } else if app.environment == .development {
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.port = 6060
    }

    let host = "0.0.0.0"
    var port = 6060
    
    // Configure custom hostname.
    switch app.environment {
    case .production:
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.port = 6060
        port = 6060
    case .staging:
      app.http.server.configuration.port = 6061
      app.http.server.configuration.hostname = "0.0.0.0"
        port = 6061
    case .development:
        app.http.server.configuration.port = 6060
        app.http.server.configuration.hostname = "0.0.0.0"
        port = 6060
    default:
        app.http.server.configuration.port = 6060
        app.http.server.configuration.hostname = "0.0.0.0"
        port = 6060
    }

    try routes(app)
    let baseURL = "http://\(host):\(port)"
    
    app.router = siteRouter
        .baseURL(baseURL)
        .eraseToAnyParserPrinter()
    
    app.mount(app.router, use: siteHandler)

}
