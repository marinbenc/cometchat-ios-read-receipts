//
//  ChatService.swift
//  CometChat
//
//  Created by Marin Benčević on 09/08/2019.
//  Copyright © 2019 marinbenc. All rights reserved.
//

import Foundation
import CometChatPro

extension String: Error {}

/// A class that deals with communicating back and forth with CometChat.
final class ChatService {
  
  private enum Constants {
    #warning("Don't forget to set your API key and app ID here!")
    static let cometChatAPIKey = "API_KEY"
    static let cometChatAppID = "APP_ID"
  }
  
  static let shared = ChatService()
  private init() {}
  
  /// Sets up CometChat for use. Call this function once, when the application starts up.
  static func initialize() {
    let settings = AppSettings.AppSettingsBuilder()
      .subscribePresenceForAllUsers()
      .setRegion(region: "us")
      .build()
    
    _ = CometChat(
      appId: Constants.cometChatAppID,
      appSettings: settings,
      onSuccess: { isSuccess in
        print("CometChat connected successfully: \(isSuccess)")
      },
      onError: { error in
        print(error.debugDescription)
      })
  }
  
  /// The currently logged in user.
  private var user: User?
  
  /// A callback called when the user receives a new message, or the user sends a message to CometChat.
  var onReceivedMessage: ((Message)-> Void)?
  /// A callback called when the user goes online or offline.
  var onUserStatusChanged: ((User)-> Void)?
  /// A callback called when the message becomes delivered or read.
  var onMessageStatusChanged: ((_ messageID: String, Message.DeliveryStatus)-> Void)?
  
  func login(email: String, onComplete: @escaping (Result<User, Error>)-> Void) {
    CometChat.messagedelegate = self
    CometChat.userdelegate = self
    
    CometChat.login(
      UID: email,
      apiKey: Constants.cometChatAPIKey,
      onSuccess: { [weak self] cometChatUser in
        guard let self = self else { return }
        // Convert CometChat's User to our own User struct
        self.user = User(cometChatUser)
        // CometChat methods are run in the background. Make sure to get
        // back to the main queue before returning control back to the caller
        DispatchQueue.main.async {
          onComplete(.success(self.user!))
        }
      },
      onError: { error in
        print("Error logging in:")
        print(error.errorDescription)
        DispatchQueue.main.async {
          onComplete(.failure("Error logging in"))
        }
      })
  }
  
  func send(message: String, to receiver: User) {
    guard let user = user else {
      return
    }
    
    let textMessage = TextMessage(
      receiverUid: receiver.id,
      text: message,
      receiverType: .user)
    
    CometChat.sendTextMessage(
      message: textMessage,
      onSuccess: { [weak self] cometChatMessage in
        guard let self = self else { return }
        print("Message sent")
        DispatchQueue.main.async {
          // Call the callback for "receiving" a message from the current user, so that
          // the UI can handle all messages from a single callback.
          self.onReceivedMessage?(Message(
            id: String(cometChatMessage.id),
            user: user,
            content: message,
            isIncoming: false))
        }
      },
      onError: { error in
        print("Error sending message:")
        print(error?.errorDescription ?? "")
    })
  }
  
  private var usersRequest: UsersRequest?
  /// Loads all users inside a CometChat app.
  func getUsers(onComplete: @escaping ([User])-> Void) {
    usersRequest = UsersRequest.UsersRequestBuilder().build()
    usersRequest?.fetchNext(
      onSuccess: { cometChatUsers in
        // Again, convert all CometChat users to instances of User
        let users = cometChatUsers.map(User.init)
        DispatchQueue.main.async {
          onComplete(users)
        }
      },
      onError: { error in
        onComplete([])
        print("Fetching users failed with error:")
        print(error?.errorDescription ?? "unknown")
      })
  }
  
  private var messagesRequest: MessagesRequest?
  /// Loads up to the last 50 messages sent between the current user and `sender`.
  func getMessages(from sender: User, onComplete: @escaping ([Message])-> Void) {
    guard let user = user else {
      return
    }
    
    let limit = 50
    
    messagesRequest = MessagesRequest.MessageRequestBuilder()
      .set(limit: limit)
      .set(uid: sender.id)
      .build()
    
    messagesRequest!.fetchPrevious(
      onSuccess: { fetchedMessages in
        print("Fetched \(fetchedMessages?.count ?? 0) older messages")
        guard let fetchedMessages = fetchedMessages else {
          onComplete([])
          return
        }
        
        let messages = fetchedMessages
          // Grab only text messages
          .compactMap { $0 as? TextMessage }
          // Convert them to Message, and set them as outgoing if they're not sent by the current user
          .map { Message($0, isIncoming: $0.senderUid.lowercased() != user.id.lowercased()) }
        
        DispatchQueue.main.async {
          onComplete(messages)
        }
      },
      onError: { error in
        print("Fetching messages failed with error:")
        print(error?.errorDescription ?? "unknown")
      })
  }
  
  func markAsRead(message: Message) {
    guard let messageID = Int(message.id) else {
      return
    }
    
    CometChat.markAsRead(messageId: messageID, receiverId: message.user.id, receiverType: .user)
  }
  
}

extension ChatService: CometChatMessageDelegate {
  func onTextMessageReceived(textMessage: TextMessage) {
    DispatchQueue.main.async {
      self.onReceivedMessage?(Message(textMessage, isIncoming: true))
    }
  }
  
  func onMessagesDelivered(receipt: MessageReceipt) {
    DispatchQueue.main.async {
      self.onMessageStatusChanged?(receipt.messageId, .delivered)
    }
  }
  
  func onMessagesRead(receipt: MessageReceipt) {
    DispatchQueue.main.async {
      self.onMessageStatusChanged?(receipt.messageId, .read)
    }
  }
}

extension ChatService: CometChatUserDelegate {
  
  func onUserOnline(user cometChatUser: CometChatPro.User) {
    DispatchQueue.main.async {
      self.onUserStatusChanged?(User(cometChatUser))
    }
  }
  
  func onUserOffline(user cometChatUser: CometChatPro.User) {
    DispatchQueue.main.async {
      self.onUserStatusChanged?(User(cometChatUser))
    }
  }
  
}
