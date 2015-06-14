////
////  5FriendsMessages.swift
////  5Friends
////
////  Created by Jesse Sum on 5/26/15.
////  Copyright (c) 2015 Jesse Sum. All rights reserved.
////
//
//import Foundation
//
//class Message : NSObject, JSQMessageData {
//    var text_: String
//    var senderId_: String
//    var date_: NSDate
//    var imageUrl_: String?
//    
//    convenience init(text: String?, sender: String?) {
//        self.init(text: text, sender: sender, imageUrl: nil)
//    }
//    
//    init(text: String?, sender: String?, imageUrl: String?) {
//        self.text_ = text!
//        self.senderId_ = sender!
//        self.date_ = NSDate()
//        self.imageUrl_ = imageUrl
//    }
//    
//    func text() -> String! {
//        return text_;
//    }
//    
//    func sender() -> String! {
//        return senderId_;
//    }
//    
//    func date() -> NSDate! {
//        return date_;
//    }
//    
//    func imageUrl() -> String? {
//        return imageUrl_;
//    }
//}