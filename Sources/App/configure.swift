import Vapor
import Fluent
import FluentPostgresDriver

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // MARK: Routes
    try routes(app)
    
    // MARK: Middleware (Sessions | Authentification)
    app.sessions.configuration.cookieName = "sessionID"
    app.middleware.use(app.sessions.middleware)
    app.middleware.use(UserCredentialsAuthenticator())
    app.middleware.use(UserRequestAuthenticator())
    
    // MARK: Database
    app.databases.use(.postgres(hostname: "localhost", username: "mathisfechner", password: "", database: "mathisfechner"), as: .psql)
    
    // MARK: Migrations
    app.migrations.add(CreateUser())
}
