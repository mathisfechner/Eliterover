//
//  File.swift
//  
//
//  Created by Mathis Fechner on 21.09.20.
//

import Foundation

class Elite {
    static let date = defaultDate.self
    static let view = defaultView.self
}

class defaultDate {
    static let dateFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
}

class defaultView {
    static let mainPath = "NewMain"
}
