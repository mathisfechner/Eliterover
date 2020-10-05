//
//  ErrorController.swift
//  
//
//  Created by Mathis Fechner on 26.09.20.
//

import Vapor
import Leaf

final class ErrorController {
    func notFound(req: Request) -> EventLoopFuture<View> {
        return req.view.render("SubViews/Error/notFound")
    }
}
