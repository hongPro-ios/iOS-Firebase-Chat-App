//
//  ConversationModels.swift
//  Messenger
//
//  Created by JEONGSEOB HONG on 2021/03/15.
//

import Foundation

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {   
    let date: String
    let text: String
    let isRead: Bool
}
