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
    }
    
    func start(req: Request) throws -> EventLoopFuture<View> {
        if req.auth.get(User.self) == nil {
            req.session.data["backToPath"] = "/"
            return try! UserController().getLogin(req: req)
        } else {
            return try! UserController().profile(req: req)
        }
    }
    
    func getCookie(req: Request) throws -> Response {
        req.session.data["Cookies"] = "accepted"
        return req.redirect(to: "/")
    }
}
