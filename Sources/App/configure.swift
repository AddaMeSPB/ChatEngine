import Fluent
import FluentMongoDriver
import Vapor
import APNS
import JWTKit

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    guard
        let KEY_IDENTIFIER = Environment.get("KEY_IDENTIFIER"),
        let TEAM_IDENTIFIER = Environment.get("TEAM_IDENTIFIER") else {
        fatalError("No value was found at the given public key environment 'APNSAuthKey'")
    }
    let keyIdentifier = JWKIdentifier.init(string: KEY_IDENTIFIER)
    #if os(Linux)
        app.apns.configuration = try .init( authenticationMethod: .jwt(
            key: .private(pem: Data(Environment.apnsKey.utf8)),
            keyIdentifier: .init(string: Environment.apnsKeyId),
            teamIdentifier: Environment.apnsTeamId
            ),
            topic: Environment.apnsTopic,
            environment: .production
        )
    #else
        app.apns.configuration = try .init( authenticationMethod: .jwt(
            key: .private(pem: Data(Environment.apnsKey.utf8)),
            keyIdentifier: .init(string: Environment.apnsKeyId),
            teamIdentifier: Environment.apnsTeamId
            ),
            topic: Environment.apnsTopic,
            environment: .sandbox
        )

    #endif

    guard let jwksString = Environment.process.JWKS else {
        fatalError("No value was found at the given public key environment 'JWKS'")
    }

    // Encoder & Decoder
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    ContentConfiguration.global.use(encoder: encoder, for: .json)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    // Configure custom hostname.
    #if os(Linux)
    #else
        app.http.server.configuration.hostname = "0.0.0.0"
    #endif

    try routes(app)

}
