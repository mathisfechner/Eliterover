import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: UserController())
    app.get("*") { req -> String in
        "Not Found stuff"
    }
    app.get { req in
        return "It works!"
    }
}
