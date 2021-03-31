//
//  File.swift
//  
//
//  Created by Mathis Fechner on 10.12.20.
//

import Foundation

extension String {
    func validate() -> String {
        return self.replacingOccurrences(of: "&", with: "&amp")
            .replacingOccurrences(of: "<", with: "&lt")
            .replacingOccurrences(of: ">", with: "&gt")
            .replacingOccurrences(of: "\"", with: "&quot")
            .replacingOccurrences(of: "'", with: "&#039")
            .replacingOccurrences(of: "\n", with: "<br>")
    }
}
