//
//  File.swift
//  
//
//  Created by Mathis Fechner on 05.10.20.
//
import Vapor
import Leaf
import VaporCSRF

class mainViewData: Encodable {
    var title: String
    var user: User?
    var aside: String? = nil
    var content: [contentViewData]
    var csrfToken: String
    
    
    
    init(title: String, content: [contentViewData], for req: Request, forMail: Bool = false) {
        self.title = title
        self.content = content
        self.csrfToken = req.csrf.storeToken()
        print(csrfToken)
        req.session.data["csrfSessionKey"] = csrfToken
        user = req.auth.get(User.self)
        if !forMail {self.content.insert(contentsOf: getNotes(for: req), at: 0)}
    }
    
    
    
    func getNotes(for req: Request) -> [contentViewData] {
         var notes: [contentViewData] = []
        let user = req.auth.get(User.self)
        if (user != nil){
            notes.append(UserController.addUserInformationForm(req: req))
        }

        if req.session.data["error/verifyMail"] != nil {
            req.session.data["error/verifyMail"] = nil
            notes.append(.init(id: "error/verifyMail", title: "Verify MailAdress", classID: "error", text: [
                "Es gab einen Fehler beim verifizieren deiner Mailadresse.", "Bitte fordere einen neuen Link an und versuche es erneut."
            ], buttons: [
                .init(id: "error/verifyMail", description: "OK", onclick: "hide('error/verifyMail')")
            ]))
        }
        
        if req.session.data["success/verifyMail"] != nil {
            req.session.data["success/verifyMail"] = nil
            notes.append(.init(id: "success/verifyMail", title: "eMail address confirmed", classID: "success", text: [
                "Deine eMail Adresse wurde erfolgreich bestätigt!"
            ], buttons: [.init(id: "success/verifyMail", description: "OK", onclick: "hide('success/verifyMail')")]))
        }
        
        if req.session.data["Cookies"] == nil {
            notes.append(.init(id: "cookie",
                               title: "Cookies",
                               text: [
                                "Wir nutzen Cookies, um dich wiedererkennen zu können.",
                                "Ohne Cookies vergessen wir schon, dass du dich angemeldet hast, wenn du den Loginbereich verlässt."
                               ],
                               buttons: [
                                .init(id: "cookie", description: "OK", onclick: "answer('accept/cookies', 'cookie')")
                               ]
            ))
        }
        
        if user?.email.first?.isUppercase ?? false {
            notes.append(.init(id: "email",
                               title: "Mail Adresse",
                               text: [
                                "Deine MailAdresse wurde noch nicht bestätigt.",
                                "Bitte klicke auf den Link in der Mail, die wir dir geschickt haben."
                               ], buttons: [
                                .init(id: "email", description: "Erneut senden", onclick: "answer('email/verification', 'email')")
                               ]))
        }
        
        return notes
    }
}
