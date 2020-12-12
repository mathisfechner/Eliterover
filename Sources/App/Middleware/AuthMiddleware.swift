//
//  File.swift
//  
//
//  Created by Mathis Fechner on 12.12.20.
//

import Vapor

class AuthMiddlware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let user = try? request.auth.require(User.self) else {
            return request.eventLoop.makeSucceededFuture(request.redirect(to: "/"))
        }
        return request.eventLoop.makeSucceededFuture(Response())
    }
}
