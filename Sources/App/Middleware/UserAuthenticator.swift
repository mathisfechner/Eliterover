//
//  File.swift
//
//
//  Created by Mathis Fechner on 05.09.20.
//

import Vapor
import Fluent



struct UserCredentialsAuthenticator: CredentialsAuthenticator {
    struct DTO: Content {
        var username: String
        var password: String
    }
    
    typealias Credentials = DTO
    
    func authenticate(credentials: DTO, for req: Request) -> EventLoopFuture<Void> {
        return User.query(on: req.db)
            .filter(\.$username == credentials.username.validate())
            .first()
            .map {
                do {
                    if let user = $0, try Bcrypt.verify(credentials.password, created: user.passwordHash) {
                        req.session.data["id"] = user.id?.uuidString
                        req.auth.login(user)
                    }
                } catch {}
        }
    }
}

struct UserRequestAuthenticator: RequestAuthenticator {
    func authenticate(request: Request) -> EventLoopFuture<Void> {
        User.find(UUID(uuidString: request.session.data["id"] ?? ""), on: request.db)
        .map {
            if let user = $0 {
                request.auth.login(user)
            }
        }
    }
}
