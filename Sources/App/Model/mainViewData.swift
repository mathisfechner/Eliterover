//
//  File.swift
//  
//
//  Created by Mathis Fechner on 05.10.20.
//
import Vapor
import Leaf



class mainViewData: Encodable {
    var title: String
    var user: User?
    var content: [contentViewData]
    
    init(title: String, content: [contentViewData], for req: Request) {
        self.title = title
        self.content = content
        user = req.auth.get(User.self)
        if(req.session.data["Cookies"] == nil) {
            self.content.insert(.init(id: "cookie", title: "Cookies", text: ["Wir nutzen Cookies, um dich wiedererkennen zu können.","Ohne Cookies vergessen wir schon, dass du dich angemeldet hast, wenn du den Loginbereich verlässt."], buttons: [.init(id: "cookie", description: "OK", onclick: "answer('accept/cookies', 'cookie')")]), at: 0)
        }
    }
}





class contentViewData: Encodable {
//    MARK: param
    
    let id: String
    var classID: String = "content"
    var title: String
    var text: [String]?
    var forms: [form]?
    var links: [link]?
    var buttons: [button]?

    
    
//    MARK: inits
    private init(id: String, classID: String?, title: String) {
        self.id = id
        self.title = title
        if classID != nil {self.classID += " " + classID!}
    }
    
    convenience init(id: String,  title: String, classID: String? = nil, forms: [form], links: [link]? = nil) {
        self.init(id: id, classID: classID, title: title)
        self.forms = forms
        self.links = links
    }
    
    convenience init(id: String, title: String, classID: String? = nil, text: [String], buttons: [button]? = nil) {
        self.init(id: id, classID: classID, title: title)
        self.text = text
        self.buttons = buttons
    }
    
//    MARK: struct definitions
    struct form: Encodable {
        var send: String
        var errorMessage: String?
        var input: [field]
        
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
    }
    
    struct link: Encodable {
        var href: String
        var description: String
        var classID: String
    }
    
    struct button: Encodable {
        var id: String
        var description: String
        var onclick: String
    }
}
