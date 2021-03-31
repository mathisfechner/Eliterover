//
//  Chat.swift
//  
//
//  Created by Mathis Fechner on 12.03.21.
//

import Vapor
import Fluent


class Chat: Model {
    static let schema: String = "chat"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: .userId) var user: User
    @Parent(key: .withUserId) var withUser: User
    @Field(key: .readTill) var readTill: Date?
    @Children(for: \.$from) var written: [Message]
    @Children(for: \.$to) var received: [Message]
    
    required init() {}
    
    init(id: UUID? = nil, userId: UUID, withUser: UUID, readTill: Date?) {
        self.id = id
        $user.id = userId
        $withUser.id = withUser
        self.readTill = readTill
    }
    
    static func getChat(with user: User, req: Request) -> EventLoopFuture<[Chat]> {
        return Chat.query(on: req.db)
            .with(\.$withUser)
            .all()
            .map() {
                $0.filter() {
                    $0.$user.id == req.auth.get(User.self)!.id! && $0.$withUser.id == user.id! ||
                        $0.$user.id == user.id! && $0.$withUser.id == req.auth.get(User.self)!.id!
                }
            }
    }
    static func getChats(req: Request) -> EventLoopFuture<[Chat]> {
        return req.auth.get(User.self)!.$chats.query(on: req.db)
            .with(\.$written) //eager load Chats
            .with(\.$received)
            .with(\.$withUser)
            .all()
    }
    static func getChatView(req: Request) -> EventLoopFuture<View> {
        return getChats(req: req).flatMap {
            let chats = $0.filter {$0.readTill != nil || !$0.received.isEmpty}
            var chatjs = chats.map {Chat.ChatJS(chat: $0, req: req)}
            chatjs.sort {
                $0.messages.last?.timestamp ?? Date() > $1.messages.last?.timestamp ?? Date()
            }
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try! encoder.encode(chatjs)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            return req.view.render("/Templates/Chat", ["chatData": jsonString])
        }
    }
}

extension Chat {
    struct ChatJS: Codable {
        var name: String
        var unreadMessageCount: Int
        var online: Bool
        var messages: [Message.MessageJS]
        
        init(chat: Chat, req: Request, withMessages: Bool = true) {
            name = chat.withUser.username
            online = false
            unreadMessageCount = 0
            messages = []

            if withMessages {
                for message in chat.received {
                    if chat.readTill == nil || message.timestamp! > chat.readTill! {
                        unreadMessageCount += 1
                    }
                }
                
                messages = chat.written.map {
                    Message.MessageJS(isFromMe: true, message: $0)
                }
                messages += chat.received.map {
                    Message.MessageJS(isFromMe: false, message: $0)
                }
                messages.sort() {
                    $0.timestamp < $1.timestamp
                }
            }
        }
    }
}



extension Chat {
    static let migrations: [Migration] = [migration_v1_0_0(), migration_v1_0_1()]
    
    struct migration_v1_0_0: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Chat.schema)
                .id()
                .field(.userId, .uuid, .required)
                .field(.withUserId, .uuid, .required)
                .field(.readTill, .date)
                .create()
        }
        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Chat.schema).delete()
        }
    }
    
    struct migration_v1_0_1: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Chat.schema)
                .deleteField(.readTill)
                .field(.readTill, .datetime)
                .update()
        }
        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Chat.schema).delete()
        }
    }
}

extension FieldKey {
    static var withUserId: Self {"withUserId"}
    static var readTill: Self {"readTill"}
}
