//
//  File.swift
//  
//
//  Created by Mathis Fechner on 05.09.20.
//

import Vapor

struct UserBasicAuthenticator: BasicAuthenticator {
    func authenticate(basic: BasicAuthorization, for request: Request) -> EventLoopFuture<Void> {
        if basic.username == "Test" && basic.password == "secret" {
            request.auth.login(App.User(name: "Vapor"))
        }
        return request.eventLoop.makeSucceededFuture(())
    }
}

struct UserTokenAuthenticator: BearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) -> EventLoopFuture<Void> {
        if bearer.token == "foo" {
            request.auth.login(App.User(name: "Vapor"))
        }
        return request.eventLoop.makeSucceededFuture(())
    }
}
