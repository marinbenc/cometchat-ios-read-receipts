//
//  OutgoingMessageTableViewCell.swift
//  CometChat
//
//  Created by Marin Benčević on 08/08/2019.
//  Copyright © 2019 marinbenc. All rights reserved.
//

import UIKit
import Kingfisher

class OutgoingMessageTableViewCell: UITableViewCell, MessageCell {
  
  @IBOutlet weak var userImage: UIImageView!
  @IBOutlet weak var textBubble: UIView!
  @IBOutlet weak var contentLabel: UILabel!
  @IBOutlet weak var textBubblePointer: UIImageView!
  @IBOutlet weak var bottomMargin: NSLayoutConstraint!
  
  @IBOutlet weak var deliveryStatusStackView: UIStackView!
  @IBOutlet weak var deliveryStatusIcon: UIImageView!
  @IBOutlet weak var deliveryStatusLabel: UILabel!
  
  private enum Constants {
    static let chainedMessagesBottomMargin: CGFloat = 20
    static let lastMessageBottomMargin: CGFloat = 32
  }
  
  var message: Message? {
    didSet {
      guard let message = message else {
        return
      }
      
      contentLabel.text = message.content
      userImage.kf.setImage(with: message.user.image)
      
      var deliveryText: String?
      var deliveryIcon: UIImage?
      
      switch message.deliveryStatus {
      case .delivered:
        deliveryIcon = #imageLiteral(resourceName: "checkmark_single").withRenderingMode(.alwaysTemplate)
        deliveryText = "Delivered"
      case .read:
        deliveryIcon = #imageLiteral(resourceName: "checkmark_double").withRenderingMode(.alwaysTemplate)
        deliveryText = "Read"
      case .unknown:
        break
      }
      
      deliveryStatusStackView.isHidden = deliveryText == nil
      deliveryStatusLabel.text = deliveryText
      deliveryStatusIcon.image = deliveryIcon
    }
  }
  
  var showsAvatar = true {
    didSet {
      userImage.isHidden = !showsAvatar
      textBubblePointer.isHidden = !showsAvatar
      bottomMargin.constant = showsAvatar ? Constants.lastMessageBottomMargin : Constants.chainedMessagesBottomMargin
    }
  }
  
  var showsDeliveryStatus: Bool = false {
    didSet {
      deliveryStatusStackView.isHidden = !showsDeliveryStatus
    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    textBubble.layer.cornerRadius = 6
  }
  
}
