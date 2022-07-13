import Fluent
import FluentMongoDriver
import Vapor
import APNS
import JWTKit

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
    
    var connectionString: String
    switch app.environment {
    case .production:
        guard let mongoURL = Environment.get("MONGO_DB_PRO") else {
            fatalError("No MongoDB connection string is available in MONGO_DB_PRO")
        }
        connectionString = mongoURL
    case .development:
        guard let mongoURL = Environment.get("MONGO_DB_DEV") else {
            fatalError("No MongoDB connection string is available in MONGO_DB_DEV")
        }
        connectionString = mongoURL
        print("mongoURL: \(connectionString)")
    case .staging:
        guard let mongoURL = Environment.get("MONGO_DB_STAGING") else {
            fatalError("No MongoDB connection string is available in MONGO_DB_DEV")
        }
        connectionString = mongoURL
        print("mongoURL: \(connectionString)")
    case .testing:
        guard let mongoURL = Environment.get("MONGO_DB_TESTING") else {
            fatalError("No MongoDB connection string is available in MONGO_DB_DEV")
        }
        connectionString = mongoURL
        print("mongoURL: \(connectionString)")
    default:
        guard let mongoURL = Environment.get("MONGO_DB_DEV") else {
            fatalError("No MongoDB connection string is available in MONGO_DB_DEV default \(#line)")
        }
        connectionString = mongoURL
        print("mongoURL: \(connectionString)")
    }

    try app.initializeMongoDB(connectionString: connectionString)
    try app.databases.use(.mongo(
        connectionString: connectionString
    ), as: .mongo)

    guard let jwksString = Environment.process.JWKS else {
        fatalError("No value was found at the given public key environment 'JWKS'")
    }
    try app.jwt.signers.use(jwksJSON: jwksString)

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

    // Configure custom hostname.
    switch app.environment {
    case .production:
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.port = 6060
    case .staging:
      app.http.server.configuration.port = 6061
      app.http.server.configuration.hostname = "0.0.0.0"
    case .development:
        app.http.server.configuration.port = 6060
        app.http.server.configuration.hostname = "0.0.0.0"
    default:
        app.http.server.configuration.port = 6060
        app.http.server.configuration.hostname = "0.0.0.0"
    }

    try routes(app)

}
