import Vapor

extension Application {
    // configures your application
    func setupDatabaseConnections(_ connectionString: inout String) {
        switch environment {
        case .production:
            guard let mongoURL = Environment.get("MONGO_DB_PRO") else {
                fatalError("No MongoDB connection string is available in .env.production")
            }
            connectionString = mongoURL
            
        case .development:
            guard let mongoURL = Environment.get("MONGO_DB_DEV") else {
                fatalError("\(#line) No MongoDB connection string is available in .env.development")
            }
            connectionString = mongoURL
            print("\(#line) mongoURL: \(connectionString)")
            
        case .staging:
            guard let mongoURL = Environment.get("MONGO_DB_STAGING") else {
                fatalError("\(#line) No MongoDB connection string is available in .env.development")
            }
            connectionString = mongoURL
            print("\(#line) mongoURL: \(connectionString)")
            
        case .testing:
            guard let mongoURL = Environment.get("MONGO_DB_TEST") else {
                fatalError("\(#line) No MongoDB connection string is available in .env.development")
            }
            connectionString = mongoURL
            print("\(#line) mongoURL: \(connectionString)")
            
        default:
            guard let mongoURL = Environment.get("MONGO_DB_DEV") else {
                fatalError("No MongoDB connection string is available in .env.development")
            }
            connectionString = mongoURL
            print("\(#line) mongoURL: \(connectionString)")
        }
    }

}

