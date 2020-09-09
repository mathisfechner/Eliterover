import Vapor

func routes(_ app: Application) throws {
    let protected = app.grouped(UserTokenAuthenticator())
        .grouped(UserBasicAuthenticator())
    
    protected.get("me") { req -> String in
        let user = try req.auth.require(User.self)
        return user.name+"\n"
    }
    
    app.get { req in
        return "It works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }
}
