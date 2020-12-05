//
//  File.swift
//  
//
//  Created by Mathis Fechner on 11.11.20.
//
import Vapor
import Leaf

class contentViewData: Encodable {
//    MARK: param
    
    let id: String
    var classID: String = "content"
    var title: String?
    var text: [String]?
    var forms: [form]?
    var links: [link]?
    var buttons: [button]?

    
    
//    MARK: inits
    private init(id: String, classID: String?, title: String?) {
        self.id = id
        self.title = title
        if classID != nil {self.classID += " " + classID!}
    }
    
    convenience init(id: String,  title: String, classID: String? = nil, text: [String]? = nil, forms: [form], links: [link]? = nil) {
        self.init(id: id, classID: classID, title: title)
        self.text = text
        self.forms = forms
        self.links = links
    }
    
    convenience init(id: String, title: String?, classID: String? = nil, text: [String], buttons: [button]? = nil, links: [link]? = nil) {
        self.init(id: id, classID: classID, title: title)
        self.text = text
        self.buttons = buttons
        self.links = links
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
            var restrictions: String?
            var classID: String
            
            init(description: String? = nil, identifier: String, placeholder: String, type: String, restrictions: String? = nil) {
                self.description = description
                self.identifier = identifier
                self.placeholder = placeholder
                self.type = type
                self.restrictions = restrictions
                classID = description == nil ? "singleField" : "field"
            }
        }
    }
    
    struct link: Encodable {
        var href: String
        var description: String
        var classID: String // little | normal
    }
    
    struct button: Encodable {
        var id: String
        var description: String
        var onclick: String
    }
}

