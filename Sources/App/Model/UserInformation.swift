//
//  UserInformation.swift
//  
//
//  Created by Mathis Fechner on 15.10.20.
//

import Vapor
import Fluent


class UserInformation: Model {
    static let schema: String = "userInformation"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: .userId) var user: User
    
    //MARK: introduction
    @Field(key: .imageName) var imageType: String?
    @Field(key: .imageData) var imageData: Data?
    @Field(key: .description) var description: String?
    
    
    //MARK: superficials
    @Field(key: .dateOfJoin) var dateOfJoin: Date
    @Field(key: .region) var region: String
    @Field(key: .size) var size: Int
    @Field(key: .lifeSituation) var lifeSituation: String
    @Field(key: .functions) var functions: String
    
    //MARK: character
    @Field(key: .dialect) var dialect: String
    @Field(key: .hajkEnthusiasm) var hajkEnthusiasm: Float
    @Field(key: .sarcasm) var sarcasm: Float
    
    //MARK: skills
    @Field(key: .musicality) var musicality: Float
    @Field(key: .cookingSkills) var cookingSkills: Float
    @Field(key: .christianLevel) var christianLevel: Float
    
    required init() {}
    
    init(id: UUID? = nil, userId: UUID) {
        self.id = id
        self.$user.id = userId
    }
}

//MARK: DTOSs

extension UserInformation {
    struct DTO: Content {
    }
}

//MARK: Migrations

extension UserInformation {
    static let migrations = [migration_v1_0_0()]
    
    struct migration_v1_0_0: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(UserInformation.schema)
                .id()
                .field(.userId, .uuid, .required)
                .field(.imageType, .string)
                .field(.imageData, .data)
                .field(.dateOfJoin, .date)
                .field(.region, .string)
                .field(.size, .int)
                .field(.lifeSituation, .string)
                .field(.functions, .array(of: .string))
                .field(.dialect, .string)
                .field(.hajkEnthusiasm, .float)
                .field(.musicality, .float)
                .field(.cookingSkills, .float)
                .field(.christianLevel, .float)
                .field(.sarcasm, .float)
                .create()
        }
        
        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(UserInformation.schema).delete()
        }
    }
}

//MARK: FieldKeyExtension

extension FieldKey {
    static var userId: Self {"userId"}
    
    static var imageType: Self {"imageType"}
    static var imageData: Self {"imageData"}
    static var description: Self {"description"}
    static var dateOfJoin: Self {"dateOfJoin"}
    static var region: Self {"region"}
    static var size: Self {"size"}
    static var lifeSituation: Self {"liveSituation"}
    static var functions: Self {"functions"}
    static var dialect: Self {"dialect"}
    static var hajkEnthusiasm: Self {"hajkEnthusiasm"}
    static var musicality: Self {"musicality"}
    static var cookingSkills: Self {"cookingSkills"}
    static var christianLevel: Self {"christianLevel"}
    static var sarcasm: Self {"sarcasm"}
}
