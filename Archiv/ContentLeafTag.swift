//
//  ContentLeafTag.swift
//  
//
//  Created by Mathis Fechner on 28.09.20.
//

import Vapor
import Leaf
import HTMLKit

struct ContentLeafTag: LeafTag {
    static let name = "Content"
    static var lastIndex = 0
    func render(_ ctx: LeafContext) throws -> LeafData {
        if(ctx.parameters.count > 0) {
            ContentLeafTag.lastIndex = ctx.parameters[0].int!
            return nil
        } else {
            return LeafData(ContentLeafTag.lastIndex)
        }
    }
}




struct formView: Encodable {
    var title: String
    var action: String
    var error: String?
    var input: [field]
    var links: [link]?
    
    struct field: Encodable {
        var description: String?
        var identifier: String
        var placeholder: String
        var type: String
        var classID: String
        
        init(description: String? = nil, identifier: String, placeholder: String, type: String) {
            self.description = description
            self.identifier = identifier
            self.placeholder = placeholder
            self.type = type
            classID = description == nil ? "singleField" : "field"
        }
    }
    struct link: Encodable {
        var href: String
        var description: String
    }
}
struct simpleView: Encodable {
    var title: String
    var text: [String]
    var links: [link]?
    var buttons: [button]?
    var error: Bool?
    
    struct link: Encodable {
        var href: String
        var description: String
        var classID: String
        var id: String
    }
    struct button: Encodable {
        var id: String
        var description: String
    }
}

struct ContentView: Encodable {
    var form: formView?
    var simple: simpleView?
}

struct MainContent: Encodable {
    var title: String
    var description: String
    var Content: [ContentView]
    var user: User?
    
    init(title: String, description: String, Content: [ContentView], for req: Request) {
        self.title = title
        self.description = description
        self.Content = Content
        user = req.auth.get(User.self)
        if(req.session.data["Cookies"] == nil) {
            self.Content.insert(
                ContentView(simple: .init(title: "Cookies", text: ["Wir nutzen Cookies, um dich wiedererkennen zu können.","Ohne Cookies vergessen wir schon, dass du dich angemeldet hast, wenn du den Loginbereich verlässt."], buttons: [.init(id: "cookie", description: "OK")])), at: 0)
        }
    }
}
