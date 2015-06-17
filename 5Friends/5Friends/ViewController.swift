//
//  ViewController.swift
//  5Friends
//
//  Created by Jesse Sum on 5/26/15.
//  Copyright (c) 2015 Jesse Sum. All rights reserved.
//

import UIKit
import Foundation

class ViewController: JSQMessagesViewController {
    let senderKey = "Sender"
    let timeKey = "Time"
    let groupKey = "Group"
    
    var user: FAuthData?
    
    var messages = [JSQMessage]()
    var avatars = Dictionary<String, JSQMessagesAvatarImage>()
    var outgoingBubbleImageView = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
    var incomingBubbleImageView = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
    var senderImageUrl: String!
    var batchMessages = true
    var ref: Firebase!
    let kFirebaseServerValueTimestamp = [".sv":"timestamp"]
    var groupnumber:String?
    var senderID:Int?
    
    // *** STEP 1: STORE FIREBASE REFERENCES
    var messagesRef: Firebase!
    var nameRef: Firebase!
    
    func setupFirebase() {
        println("\(self.senderId)")
        // *** STEP 2: SETUP FIREBASE
        //setup new group.
        messagesRef = Firebase(url: "https://intense-fire-9360.firebaseio.com/group\(groupnumber!)")
        
        // *** STEP 4: RECEIVE MESSAGES FROM FIREBASE (limited to latest 25 messages)
        messagesRef.queryLimitedToLast(25).observeEventType(FEventType.ChildAdded, withBlock: { (snapshot) in
            //set icebreaker if there as been no messages so far.
            let text = snapshot.value["text"] as? String
            let sender = snapshot.value["sender"] as? String
            let imageUrl = snapshot.value["imageUrl"] as? String
            let message = JSQMessage(senderId: sender, senderDisplayName: sender, date: NSDate(), text: text)
            self.messages.append(message)
            self.finishReceivingMessage()
            
        })
    }
    
    func setupSender(){
        let senderDefault = NSUserDefaults.standardUserDefaults().stringForKey(senderKey)
        let timeDefault = NSUserDefaults.standardUserDefaults().objectForKey(timeKey) as? NSDate
        let groupDefault = NSUserDefaults.standardUserDefaults().stringForKey(groupKey)
        
        if senderDefault != nil {
            println("this is senderdefault not nill")
            let date = NSDate()
            println("This is the date right now: \(date)")
            println("this is the saved date: \(timeDefault!)")
            if date.compare(timeDefault!) == NSComparisonResult.OrderedDescending {
                getSenderID()
            } else {
                println("this is senderdefaul")
                self.senderId = senderDefault
                self.senderDisplayName = senderDefault
                self.groupnumber = groupDefault
                setupSenderAvatar()
            }
        } else {
            println("this is senderdefault nill")
            getSenderID()
        }
    }
    
    func getSenderID(){
        var godRef = Firebase(url: "https://intense-fire-9360.firebaseio.com/GOD/-JpuKz1zV_-sI6FGr4YH/current")
        println("THis is inside the godref")
        
        godRef.runTransactionBlock({
            (currentData:FMutableData!) in
            var value = currentData.value as? Int
            if value == nil {
                value = 0
            }
            println("This is incrementing super duper slowly.")
            currentData.value = value! + 1
            return FTransactionResult.successWithValue(currentData)
            },
            andCompletionBlock: {(error, commited, snapshot) in
                var value = snapshot.value as? Int
                println("this is inside the completionblock")
                self.senderID = (((value! - 1) % 5) + 1)
                self.groupnumber = "\((value! - 1) / 5)"
                
                let date = NSDate()
                let calendar = NSCalendar.currentCalendar()
                calendar.dateBySettingHour(0, minute: 0, second: 0, ofDate: date, options: NSCalendarOptions())!
                let thisSunday = calendar.dateBySettingUnit(.WeekdayCalendarUnit, value: 1, ofDate: date, options: NSCalendarOptions())
                
                println("this is the sunday: \(thisSunday!)")
                
                NSUserDefaults.standardUserDefaults().setObject(self.groupnumber, forKey: self.groupKey)
                NSUserDefaults.standardUserDefaults().setObject(thisSunday, forKey: self.timeKey)

                if (self.senderID! - 1) == 0 {
                    self.sendIceBreaker()
                }

                PFPush.subscribeToChannel("jesse", error: nil)
                PFPush.subscribeToChannelInBackground("group\(self.groupnumber!)", block: nil)
                println("these are the channels: \(PFPush.getSubscribedChannels(nil))")
                self.setUpSenderName()
                return
        })
    }
    
    func setUpSenderName(){
        var nameRef = Firebase(url:"https://intense-fire-9360.firebaseio.com/Names")
        println("setting up name")
        nameRef.observeEventType(.Value, withBlock: { snapshot in
            var names = snapshot.value as! [String]
//            self.senderId = "\(self.senderID!)"
            self.senderId = names[self.senderID!]
            self.senderDisplayName = names[self.senderID!]
            println("this is new senderid = \(self.senderId)")
            println("\(self.senderDisplayName)")
            NSUserDefaults.standardUserDefaults().setObject(self.senderDisplayName, forKey: self.senderKey)
            self.setupSenderAvatar()
            }, withCancelBlock: { error in
                println(error.description)
        })
    }
    
    
    func setupSenderAvatar(){
        let profileImageUrl = user?.providerData["cachedUserProfile"]?["profile_image_url_https"] as? NSString
        if let urlString = profileImageUrl {
            setupAvatarImage(senderDisplayName, imageUrl: urlString as String, incoming: false)
            senderImageUrl = urlString as String
        } else {
            setupAvatarColor(senderDisplayName, incoming: false)
            senderImageUrl = ""
        }
        
        setupFirebase()
    }
    
    func sendMessage(text: String!, sender: String!) {
        // *** STEP 3: ADD A MESSAGE TO FIREBASE
        
        println("this is the sender \(sender)")
        if (sender == "default"){
            return
        }
        
        messagesRef.childByAutoId().setValue([
            "text":text,
            "sender":sender,
            "imageUrl":senderImageUrl,
            "created":kFirebaseServerValueTimestamp
            ])
        
        sendParse(text)
    }
    
    func sendParse(text: String!){
        let push = PFPush()
        
        // Be sure to use the plural 'setChannels'.
        push.setChannel("group\(self.groupnumber!)")
        push.setData([ "alert": "\(text)", "badge": "Increment", "sound": "default" ])
        push.sendPush(nil)
    }
    
    func JSONStringify(value: AnyObject, prettyPrinted: Bool = false) -> String {
        var options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : nil
        if NSJSONSerialization.isValidJSONObject(value) {
            if let data = NSJSONSerialization.dataWithJSONObject(value, options: options, error: nil) {
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    return string as String
                }
            }
        }
        return ""
    }
    
    func sendIceBreaker(){
        var iceBreakerRef = Firebase(url:"https://intense-fire-9360.firebaseio.com/IceBreaker")
        
        iceBreakerRef.observeEventType(.Value, withBlock: { snapshot in
            var text = snapshot.value as! String
            var groupRef = Firebase(url: "https://intense-fire-9360.firebaseio.com/group\(self.groupnumber!)")
            groupRef.childByAutoId().setValue([
                "text":text,
                "sender":"5Friends",
                "imageUrl":"",
                "created":self.kFirebaseServerValueTimestamp
                ])
            }, withCancelBlock: { error in
                println(error.description)
        })

    }
    
    
    func tempSendMessage(text: String!, sender: String!) {
        let message = JSQMessage(senderId: sender, senderDisplayName: sender, date: NSDate(), text: text)
        messages.append(message)
    }
    
    func setupAvatarImage(name: String, imageUrl: String?, incoming: Bool) {
        if let stringUrl = imageUrl {
            if let url = NSURL(string: stringUrl) {
                if let data = NSData(contentsOfURL: url) {
                    let image = UIImage(data: data)
                    let diameter = incoming ? UInt(collectionView.collectionViewLayout.incomingAvatarViewSize.width) : UInt(collectionView.collectionViewLayout.outgoingAvatarViewSize.width)
                    let avatarImage = JSQMessagesAvatarImageFactory.avatarImageWithImage(image, diameter: diameter)
                    avatars[name] = avatarImage
                    return
                }
            }
        }
        
        // At some point, we failed at getting the image (probably broken URL), so default to avatarColor
        setupAvatarColor(name, incoming: incoming)
    }
    
    func setupAvatarColor(name: String, incoming: Bool) {
        let diameter = incoming ? UInt(collectionView.collectionViewLayout.incomingAvatarViewSize.width) : UInt(collectionView.collectionViewLayout.outgoingAvatarViewSize.width)
        
        let rgbValue = name.hash
        let r = CGFloat(Float((rgbValue & 0xFF0000) >> 16)/255.0)
        let g = CGFloat(Float((rgbValue & 0xFF00) >> 8)/255.0)
        let b = CGFloat(Float(rgbValue & 0xFF)/255.0)
        let color = UIColor(red: r, green: g, blue: b, alpha: 0.5)
        
        let nameLength = count(name)
        let initials : String? = name.substringToIndex(advance(senderDisplayName.startIndex, min(1, nameLength)))
        let userImage = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials(initials, backgroundColor: color, textColor: UIColor.blackColor(), font: UIFont.systemFontOfSize(CGFloat(13)), diameter: diameter)
        
        avatars[name] = userImage
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        JSQMessagesCollectionViewCell.registerMenuAction("reportuser:")
        UIMenuController.sharedMenuController().menuItems = [UIMenuItem(title: "Report User", action: "reportuser:")]
        
        inputToolbar.contentView.leftBarButtonItem = nil
        automaticallyScrollsToMostRecentMessage = true
        navigationController?.navigationBar.topItem?.title = "5Friends"
        self.senderId = "default"
        self.senderDisplayName = "default"
        setupSender()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.collectionViewLayout.springinessEnabled = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if ref != nil {
            ref.unauth()
        }
    }
    
    // ACTIONS
    
    func receivedMessagePressed(sender: UIBarButtonItem) {
        // Simulate reciving message
        showTypingIndicator = !showTypingIndicator
        scrollToBottomAnimated(true)
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            self.sendMessage(text, sender: senderId)
            dispatch_async(dispatch_get_main_queue()) {
                self.finishSendingMessage()
            }
        }

        

    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        println("Camera pressed!")
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            return outgoingBubbleImageView
        }
        
        return incomingBubbleImageView
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.item]
        if let avatar = avatars[message.senderId] {
            return avatar
//            return UIImageView(image: avatar)
        } else {
            setupAvatarImage(message.senderId, imageUrl: nil, incoming: true)
            return avatars[message.senderId]
//            return UIImageView(image:avatars[message.senderId])
        }
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        
        cell.canPerformAction("reportuser:", withSender: senderId)
        
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            cell.textView.textColor = UIColor.blackColor()
        } else {
            cell.textView.textColor = UIColor.whiteColor()
        }
        
        let attributes : [NSObject:AnyObject] = [NSForegroundColorAttributeName:cell.textView.textColor, NSUnderlineStyleAttributeName: 1]
        cell.textView.linkTextAttributes = attributes
        
        return cell
    }
    
    
    // View  usernames above bubbles
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item];
        
        // Sent by me, skip
        if message.senderId == senderId {
            return nil;
        }
        
        // Same as previous sender, skip
        if indexPath.item > 0 {
            let previousMessage = messages[indexPath.item - 1];
            if previousMessage.senderId == message.senderId {
                return nil;
            }
        }
        
        return NSAttributedString(string:message.senderId)
    }
    
    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject!) -> Bool {
        if (action == "reportuser:") {
                return true
        }
        
        return super.collectionView(collectionView, canPerformAction: action, forItemAtIndexPath: indexPath, withSender: sender)
    }
    
    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject!) {
        println("this is the item path: \(indexPath.item)")
        println("\(messages[indexPath.item])")
        if (action == "reportuser:") {
            reportUser(messages[indexPath.item])
        }
    }
    
    func reportUser(sender: AnyObject!){
        let push = PFPush()
        let reportedUser = sender.senderId()
        // Be sure to use the plural 'setChannels'.
        push.setChannel("Admin")
        push.setData([ "alert": "This is the person they are reporting on: \(reportedUser) at group: \(self.groupnumber!)", "badge": "Increment", "sound": "default" ])
        push.sendPush(nil)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let message = messages[indexPath.item]
        
        // Sent by me, skip
        if message.senderId == senderId {
            return CGFloat(0.0);
        }
        
        // Same as previous sender, skip
        if indexPath.item > 0 {
            let previousMessage = messages[indexPath.item - 1];
            if previousMessage.senderId == message.senderId {
                return CGFloat(0.0);
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
}

