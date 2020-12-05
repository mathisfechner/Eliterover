//
//  MailController.swift
//  
//
//  Created by Mathis Fechner on 02.11.20.
//

import Vapor
import Smtp

final class MailController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post("email", "verification", use: getMailAddressVerification)
        routes.get("email", "verification", ":id", ":emailHash", use: postMailAddressVerification)
        routes.get("email", "test", use: mailTest)
    }
    
    func getMailAddressVerification(req: Request) throws -> HTTPResponseStatus {
        let user = req.auth.get(User.self)
        if user?.email.first?.isUppercase ?? false {
            MailController.sendVerificationLink(req: req, user: user!)
            return HTTPResponseStatus.ok
        }
        return HTTPResponseStatus.ok
    }
    
    func postMailAddressVerification(req:Request) throws -> EventLoopFuture<Response> {
        if let id = req.parameters.get("id"), let emailHash = req.parameters.get("emailHash") {
            return User.find(UUID(uuidString: id), on: req.db).flatMap() {
                if (try? Bcrypt.verify($0?.email ?? "", created: Elite.routing.decodeValidURLComponent(from: emailHash))) ?? false {
                    $0?.email = $0!.email.lowercased()
                    return ($0!.save(on: req.db).map() {
                        req.session.data["success/verifyMail"] = Elite.date.setErrorDate()
                        return req.redirect(to: "/")
                    })
                }
                req.session.data["error/verifyMail"] = Elite.date.setErrorDate()
                return req.eventLoop.makeSucceededFuture(req.redirect(to: "/"))
            }
        }
        req.session.data["error/verifyMail"] = Elite.date.setErrorDate()
        return req.eventLoop.makeSucceededFuture(req.redirect(to: "/"))
    }
    
    static func sendVerificationLink(req: Request, user: User) {
        let emailAddressHash = Elite.routing.makeValidURLComponent(from: (try? Bcrypt.hash(user.email)) ?? "")
        let emailContent = mainViewData(title: "Verification", content: [
            .init(id: "verification", title: nil, text: [
                "Moin \(user.firstname),",
                "Bitte klicke folgenden Link, um deine Mailadresse zu bestätigen:",
            ], links: [
                .init(href: "http://localhost:8080/email/verification/\(user.id!.uuidString)/\(emailAddressHash)", description: "Email Adresse verifizieren", classID: "normal")
            ])
        ], for: req, forMail: true)
        _ = req.view.render(Elite.view.mainMailPath, emailContent).map() {(content: View) in
            let body = String(buffer: content.data)
            let email = Email(from: EmailAddress(address: Elite.mail.sendAddress, name: Elite.mail.sendName),
                              to: [EmailAddress(address: user.email, name: user.firstname+" "+user.lastname)],
                              cc: nil,
                              bcc: nil,
                              subject: "Email Adresse bestätigen",
                              body: body,
                              isBodyHtml: true,
                              replyTo: nil)
            _ = req.smtp.send(email).map { result in
                switch result {
                case .success:
                    print("Email has been sent")
                case .failure(let error):
                    print("Email has not been sent: \(error)")
                }
            }
        }
    }
    
    func mailTest(req: Request) throws -> EventLoopFuture<View> {
        let user = try req.auth.require(User.self)
        let emailAddressHash = Elite.routing.makeValidURLComponent(from: (try? Bcrypt.hash(user.email)) ?? "")

        let emailContent = mainViewData(title: "Verification", content: [
            .init(id: "verification", title: nil, text: [
                "Moin \(user.firstname),",
                "Bitte klicke folgenden Link, um deine Mailadresse zu bestätigen:",
            ], links: [
                .init(href: "http://localhost:8080/email/verification/\(user.id!.uuidString)/\(emailAddressHash)", description: "Email Adresse verifizieren", classID: "normal")
            ])
        ], for: req, forMail: true)
        return req.view.render(Elite.view.mainMailPath, emailContent)
    }
}
