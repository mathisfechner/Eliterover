//
//  File.swift
//  
//
//  Created by Mathis Fechner on 21.09.20.
//

import Foundation
import Vapor

class Elite {
    static let routing = defaultRouting.self
    static let date = defaultDate.self
    static let view = defaultView.self
    static let mail = defaultMail.self
}

class defaultRouting {
    static func makeValidURLComponent(from component: String) -> String {
        return component.replacingOccurrences(of: "$", with: "$1").replacingOccurrences(of: "/", with: "$2")
    }
    static func decodeValidURLComponent(from component: String) -> String {
        return component.replacingOccurrences(of: "$2", with: "/").replacingOccurrences(of: "$1", with: "$")
    }
    static func validate(input: String) -> String {
        return input.validate()
    }
}

class defaultDate {
    static let dateFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
    static func setErrorDate() -> String {
        return dateFormatter.string(from: Date())
    }
    static func stillActiveError(_ errorDate: String?, duration: Int = 60) -> Bool {
        if let date = errorDate {
            return Date().timeIntervalSince(dateFormatter.date(from: date) ?? Date()) < TimeInterval(duration)
        }
        return false
    }
    static let inputFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.dateFormat = "dd'.'MM'.'yyyy"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

class defaultView {
    static let mainPath = "/Templates/Main"
    static let mainMailPath = "/Templates/MainMail"
}

class defaultMail {
    static let sendAddress = "Elite@bps-hannover.de"
    static let sendName = "Elite"
}
