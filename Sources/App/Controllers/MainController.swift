//
//  File.swift
//
//
//  Created by Mathis Fechner on 19.09.20.
//

import Vapor
import Leaf

final class MainController : RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("", use: start)
        routes.get("accept", "cookies", use: getCookie)
        routes.get("quit", use: quit)
        routes.get("test", use: test)
    }
    
    func test(req: Request) throws -> EventLoopFuture<View> {
        struct Context: Encodable {
            let title: String
            let body: String
        }
        let context = Context(title: "Leaf 4", body:"Hello Leaf Tau!")
        return req.view.render("index", context)
    }
    
    func start(req: Request) throws -> EventLoopFuture<View> {
        if req.auth.get(User.self) == nil {
            req.session.data["backToPath"] = "/"
            return try! UserController().getLogin(req: req)
        } else {
            return try! UserController().profile(req: req)
        }
    }
    
    func getCookie(req: Request) throws -> HTTPResponseStatus {
        req.session.data["Cookies"] = "accepted"
        return HTTPResponseStatus.ok
    }
    
    func quit(req: Request) throws -> HTTPResponseStatus {
        exit(0)
    }
}
