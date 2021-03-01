//
//  UserInformation.swift
//
//
//  Created by Mathis Fechner on 15.10.20.
//

import Vapor
import Fluent


class ProfilePic: Model {
    static let schema: String = "profilePic"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: .userId) var user: User

    @Field(key: .imageType) var imageType: String
    @Field(key: .imageData) var imageData: Data
    
    required init() {}
    
    init(id: UUID? = nil, userId: UUID, imageType: String, imageData: Data) {
        self.id = id
        $user.id = userId
        self.imageType = imageType
        self.imageData = imageData
        frame()
    }
    
    init?(DTO: DTO, user: User) {
        if let userId = user.id, let type = DTO.imageData.contentType?.subType {
            self.$user.id = userId
            self.imageType = type
        } else {return nil}
        self.imageData = Data(DTO.imageData.data.readableBytesView)
        frame()
    }
    
    //MARK: Handler
    func frame() {
        
    }
}

//MARK: DTOSs
extension ProfilePic {
    struct DTO: Content {
        var imageData: File
    }
}

//MARK: Migrations

extension ProfilePic {
    static let migrations = [migration_v1_0_0()]
    
    struct migration_v1_0_0: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(ProfilePic.schema)
                .id()
                .field(.userId, .uuid, .required)
                .foreignKey(.userId, references: User.schema, .id)
                .field(.imageType, .string, .required)
                .field(.imageData, .data, .required)
                .unique(on: .userId)
                .create()
        }
        
        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(ProfilePic.schema).delete()
        }
    }
}


//MARK: FieldKeyExtension

extension FieldKey {
    static var userId: Self {"userId"}
    static var pictureId: Self {"pictureId"}
    static var imageType: Self {"imageType"}
    static var imageData: Self {"imageData"}
}
