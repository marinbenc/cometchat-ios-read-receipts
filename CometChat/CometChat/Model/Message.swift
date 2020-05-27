//
//  Message.swift
//  CometChat
//
//  Created by Marin Benčević on 08/08/2019.
//  Copyright © 2019 marinbenc. All rights reserved.
//

import UIKit
import CometChatPro

struct Message {
  enum DeliveryStatus {
    case unknown, delivered, read
  }
  
  let id: String
  let user: User
  let content: String
  let isIncoming: Bool
  var deliveryStatus: DeliveryStatus = .unknown
}

extension Message {
  init(_ textMessage: TextMessage, isIncoming: Bool) {
    user = User(
      id: textMessage.senderUid,
      name: textMessage.sender?.name ?? "unknown",
      image: textMessage.sender?.avatar.flatMap(URL.init),
      isOnline: textMessage.sender?.status == .some(.online))
    
    if textMessage.deliveredAt > 0 {
      deliveryStatus = .delivered
    }
    
    if textMessage.readAt > 0 {
      deliveryStatus = .read
    }
    
    content = textMessage.text
    id = String(textMessage.id)
    self.isIncoming = isIncoming
  }
}
