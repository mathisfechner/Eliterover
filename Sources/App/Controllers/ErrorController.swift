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
        return req.view.render(Elite.view.mainPath, mainViewData.init(title: "Error", content: [
            .init(id: "notFound", title: "Not Found", classID: "error", text: ["Wir müssen dir was sagen!", "Es liegt nicht an dir, es liegt an uns. Wir haben uns irgendwie auseinander gelebt.", "Wir haben das Gefühl, dir nicht geben zu können, was du verdienst.", "Tut uns Leid, du findest bestimmt etwas besseres!"])
        ], for: req))
    }
    
    static func registrationError(req: Request) -> contentViewData {
        return contentViewData(id: "registrationError", title: "Und nochmal...", classID: "error", text: ["Das geht uns gerade alle ein bisschen zu schnell, vielleicht wollen wir es nochmal langsamer angehen?", "Wir brauchen einfach ein bisschen unseren Freiraum und können uns nicht so schnell binden"])
    }
}
