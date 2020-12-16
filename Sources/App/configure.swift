import Vapor
import Leaf
import Fluent
import FluentPostgresDriver
import VaporCSRF

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
    //app.middleware.use(CSRFMiddleware())

    //csrf key
    //app.csrf.setTokenContentKey("csrfToken")


    
    // MARK: Database
    app.databases.use(.postgres(hostname: "192.168.2.124", username: "max", password: "max", database: "EliteDB"), as: .psql)
    // MARK: Leaf
    app.views.use(.leaf)
    app.leaf.cache.isEnabled = app.environment.isRelease
    app.leaf.configuration.rootDirectory = "Sources/App/Views"
    
    // MARK: Migrations
    app.migrations.add(User.migrations)
    app.migrations.add(UserInformation.migrations)
    try app.autoMigrate().wait()
}
