import Vapor
import Leaf
import Fluent
import FluentPostgresDriver

// configures your application
public func configure(_ app: Application) throws {

    // MARK: Routes
    try routes(app)
    
    // MARK: Middleware (Sessions | Authentification)
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.sessions.configuration.cookieName = "sessionID"
    app.middleware.use(app.sessions.middleware)
    app.middleware.use(UserCredentialsAuthenticator())
    app.middleware.use(UserRequestAuthenticator())
    
    // MARK: Database
    app.databases.use(.postgres(hostname: "localhost", username: "mathisfechner", password: "", database: "mathisfechner"), as: .psql)
    // MARK: Leaf
    app.views.use(.leaf)
    app.leaf.cache.isEnabled = app.environment.isRelease
    app.leaf.configuration.rootDirectory = "/Users/mathisfechner/Documents/Swift/Vapor/Eliterover/Sources/App/Views"
    
    // MARK: Migrations
    app.migrations.add(CreateUser())
}
