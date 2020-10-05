//
//  File.swift
//
//
//  Created by Mathis Fechner on 18.09.20.
//

import Vapor
import Leaf

final class CSSController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("style.css", use: mainCss)
    }
    
    func mainCss(req: Request) throws -> EventLoopFuture<Response> {
        return req.view.render("css/style").encodeResponse(status: .ok, headers: ["Content-Type":"text/css"], for: req)
    }
}
