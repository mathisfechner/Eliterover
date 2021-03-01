//
//  UserInformation.swift
//  
//
//  Created by Mathis Fechner on 15.10.20.
//

import Vapor
import Fluent


struct Characteristics2: Codable {
    //MARK: introduction
    var description: String
    
    //MARK: superficials
    var height: Int
    var region: String
    var lifeSituation: String
    var positions: [String]
    
    //MARK: character
    var dialect: String
    var hajkEnthusiasm: Float
    var sarcasm: Float
    var christianLevel: Float
    
    //MARK: skills
    var musicality: Float
    var cookingSkills: Float
}

struct Characteristics: Codable {
    //MARK: introduction
    var description: String
    
    //MARK: superficials
    var height: String
    var region: String
    var lifeSituation: String
    var positions: String
    
    //MARK: character
    var dialect: String
    var hajkEnthusiasm: String
    var sarcasm: Float
    var christianLevel: String
    
    //MARK: skills
    var musicality: String
    var cookingSkills: String
}
