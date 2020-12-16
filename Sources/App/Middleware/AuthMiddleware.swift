//
//  File.swift
//  
//
//  Created by Mathis Fechner on 12.12.20.
//

import Vapor

public class AuthMiddlware: Middleware {
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard (try? request.auth.require(User.self)) != nil else {
            request.session.data["backToPath"] = request.url.description
            return request.eventLoop.makeSucceededFuture(request.redirect(to: "/login"))
        }
        return next.respond(to: request)
    }
}
