//
//  Message.swift
//  
//
//  Created by Mathis Fechner on 18.03.21.
//

import Vapor
import Fluent


class Message: Model {
    static let schema: String = "message"
    
    @ID(key: .id) var id: UUID?
    @Timestamp(key: .timestamp, on: .create, format: .iso8601) var timestamp: Date?
    @OptionalParent(key: .responseTo) var responseTo: Message?
    @Children(for: \.$responseTo) var answers: [Message]
    
    @Parent(key: .from) var from: Chat
    @Parent(key: .to) var to: Chat
    
    @Field(key: .body) var messageBody: String
    
    required init() {}
    
    init(id: UUID? = nil, responseTo: Message? = nil, from: Chat, to: Chat, messageBody: String) {
        self.id = id
        $responseTo.id = responseTo?.id
        $from.id = from.id!
        $to.id = to.id!
        self.messageBody = messageBody
    }
    
    static func newMessage(messageDTO: MessageDTO, req: Request, ws: WebSocket, wsConnections: [WsConnection]) {
        _ = User.getUser(username: messageDTO.to, req: req).map {
            let toUserId = $0.id?.uuidString
            _ = Chat.getChat(with: $0, req: req).map {
                var from: Chat?
                var to: Chat?
                for chat in $0 {
                    if chat.$user.id == req.auth.get(User.self)!.id! {
                        from = chat
                    } else {
                        to = chat
                    }
                }
                let resultMessage = Message(from: from!, to: to!, messageBody: messageDTO.messageBody.validate())
                _ = resultMessage.create(on: req.db).map {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    encoder.dateEncodingStrategy = .iso8601
                    var chatJS = Chat.ChatJS(chat: from ?? Chat(), req: req, withMessages: false)
                    chatJS.messages = [MessageJS(isFromMe: true, message: resultMessage)]
                    var jsonstring = String(data: try! encoder.encode(chatJS), encoding: .utf8)!
                    ws.send(jsonstring)
                    
                    for connection in wsConnections {
                        if connection.userID == toUserId {
                            chatJS = Chat.ChatJS(chat: to ?? Chat(), req: req, withMessages: false)
                            chatJS.messages = [MessageJS(isFromMe: false, message: resultMessage)]
                            jsonstring = String(data: try! encoder.encode(chatJS), encoding: .utf8)!
                            connection.ws.send(jsonstring)
                            break
                        }
                    }
                }
            }
        }

    }
}

extension Message {
    struct MessageJS: Codable, Content {
        var id: String
        var timestamp: Date
        var responseTo: String
        var isFromMe: Bool
        var messageBody: String
        
        init(isFromMe: Bool, message: Message) {
            id = message.id?.uuidString ?? "Not in Database"
            timestamp = message.timestamp!
            responseTo = message.$responseTo.id?.uuidString ?? ""
            self.isFromMe = isFromMe
            messageBody = message.messageBody
        }
    }
    
    struct MessageDTO: Content {
        var to: String
        var responseTo: String?
        var messageBody: String
    }
}


extension Message {
    static let migrations: [Migration] = [migration_v1_0_0(), migration_v1_0_1()]
    
    struct migration_v1_0_0: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Message.schema)
                .id()
                .field(.timestamp, .date, .required)
                .field(.responseTo, .uuid)
                .field(.from, .uuid, .required)
                .field(.to, .uuid, .required)
                .field(.body, .string)
                .create()
        }
        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Message.schema).delete()
        }
    }
    struct migration_v1_0_1: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Message.schema)
                .deleteField(.timestamp)
                .field(.timestamp, .string, .required)
                .update()
        }
        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Message.schema).delete()
        }
    }
}


extension FieldKey {
    static var timestamp: Self {"time"}
    static var responseTo: Self {"responseTo"}
    static var from: Self {"from"}
    static var to: Self {"to"}
    static var body: Self {"body"}
}
