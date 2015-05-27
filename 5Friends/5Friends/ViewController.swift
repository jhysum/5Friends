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
    
    var messages = [Message]()
    var avatars = Dictionary<String, UIImage>()
    var outgoingBubbleImageView = JSQMessagesBubbleImageFactory.outgoingMessageBubbleImageViewWithColor(UIColor.jsq_messageBubbleLightGrayColor())
    var incomingBubbleImageView = JSQMessagesBubbleImageFactory.incomingMessageBubbleImageViewWithColor(UIColor.jsq_messageBubbleGreenColor())
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
        println("\(self.sender)")
        // *** STEP 2: SETUP FIREBASE
        //setup new group.
        messagesRef = Firebase(url: "https://intense-fire-9360.firebaseio.com/group\(groupnumber!)")
        
        // *** STEP 4: RECEIVE MESSAGES FROM FIREBASE (limited to latest 25 messages)
        messagesRef.queryLimitedToLast(25).observeEventType(FEventType.ChildAdded, withBlock: { (snapshot) in
            //set icebreaker if there as been no messages so far.
            let text = snapshot.value["text"] as? String
            let sender = snapshot.value["sender"] as? String
            let imageUrl = snapshot.value["imageUrl"] as? String
            let message = Message(text: text, sender: sender, imageUrl: imageUrl)
            self.messages.append(message)
            self.finishReceivingMessage()
            
        })
    }
    
    func setupSender(){
        let senderDefault = NSUserDefaults.standardUserDefaults().stringForKey(senderKey)
        let timeDefault = NSUserDefaults.standardUserDefaults().objectForKey(timeKey) as? NSDate
        let groupDefault = NSUserDefaults.standardUserDefaults().stringForKey(groupKey)
        
        
        if senderDefault != nil {
            println("this is true! this is the senderdefault: \(senderDefault), and timeDefault: \(timeDefault)")
            
            let date = NSDate()
            if date.compare(timeDefault!) == NSComparisonResult.OrderedDescending {
                getSenderID()
            } else {
                self.sender = senderDefault
                self.groupnumber = groupDefault
                setupSenderAvatar()
            }
        } else {
            println("getSenderID")
            getSenderID()
        }
    }
    
    func getSenderID(){
        var godRef = Firebase(url: "https://intense-fire-9360.firebaseio.com/GOD/-JpuKz1zV_-sI6FGr4YH/current")
        
        godRef.runTransactionBlock({
            (currentData:FMutableData!) in
            var value = currentData.value as? Int
            if value == nil {
                value = 0
            }
            
            currentData.value = value! + 1
            return FTransactionResult.successWithValue(currentData)
            },
            {(error, commited, snapshot) in
                println("\(snapshot.value!)")
                var value = snapshot.value as? Int
                self.senderID = (((value! - 1) % 5) + 1)
                println("\(self.senderID)")
                self.groupnumber = "\((value! - 1) / 5)"
                
                let date = NSDate()
                let calendar = NSCalendar.currentCalendar()
                calendar.dateBySettingHour(0, minute: 0, second: 0, ofDate: date, options: NSCalendarOptions())!
                let thisSunday = calendar.dateBySettingUnit(.WeekdayCalendarUnit, value: 1, ofDate: date, options: NSCalendarOptions())
                
                NSUserDefaults.standardUserDefaults().setObject(self.groupnumber, forKey: self.groupKey)
                NSUserDefaults.standardUserDefaults().setObject(thisSunday, forKey: self.timeKey)
                
                println("this is the groupnumber: \(self.groupnumber!)")
                println("this sunday: \(thisSunday!)")
                if (self.senderID! - 1) == 0 {
                    self.sendIceBreaker()
                }
                self.setUpSenderName()
                return
        })
    }
    
    func setUpSenderName(){
        var nameRef = Firebase(url:"https://intense-fire-9360.firebaseio.com/Names")
        
        nameRef.observeEventType(.Value, withBlock: { snapshot in
            var names = snapshot.value as [String]
            self.sender = names[self.senderID!]
            NSUserDefaults.standardUserDefaults().setObject(self.sender, forKey: self.senderKey)
            self.setupSenderAvatar()
            }, withCancelBlock: { error in
                println(error.description)
        })
    }
    
    
    func setupSenderAvatar(){
        let profileImageUrl = user?.providerData["cachedUserProfile"]?["profile_image_url_https"] as? NSString
        if let urlString = profileImageUrl {
            setupAvatarImage(sender, imageUrl: urlString, incoming: false)
            senderImageUrl = urlString
        } else {
            setupAvatarColor(sender, incoming: false)
            senderImageUrl = ""
        }
        
        setupFirebase()
    }
    
    func sendMessage(text: String!, sender: String!) {
        // *** STEP 3: ADD A MESSAGE TO FIREBASE
        messagesRef.childByAutoId().setValue([
            "text":text,
            "sender":sender,
            "imageUrl":senderImageUrl,
            "created":kFirebaseServerValueTimestamp
            ])
    }
    
    func sendIceBreaker(){
        var iceBreakerRef = Firebase(url:"https://intense-fire-9360.firebaseio.com/IceBreaker")
        
        iceBreakerRef.observeEventType(.Value, withBlock: { snapshot in
            var text = snapshot.value as String
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
        let message = Message(text: text, sender: sender, imageUrl: senderImageUrl)
        messages.append(message)
    }
    
    func setupAvatarImage(name: String, imageUrl: String?, incoming: Bool) {
        if let stringUrl = imageUrl {
            if let url = NSURL(string: stringUrl) {
                if let data = NSData(contentsOfURL: url) {
                    let image = UIImage(data: data)
                    let diameter = incoming ? UInt(collectionView.collectionViewLayout.incomingAvatarViewSize.width) : UInt(collectionView.collectionViewLayout.outgoingAvatarViewSize.width)
                    let avatarImage = JSQMessagesAvatarFactory.avatarWithImage(image, diameter: diameter)
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
        
        let nameLength = countElements(name)
        let initials : String? = name.substringToIndex(advance(sender.startIndex, min(1, nameLength)))
        let userImage = JSQMessagesAvatarFactory.avatarWithUserInitials(initials, backgroundColor: color, textColor: UIColor.blackColor(), font: UIFont.systemFontOfSize(CGFloat(13)), diameter: diameter)
        
        avatars[name] = userImage
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        inputToolbar.contentView.leftBarButtonItem = nil
        automaticallyScrollsToMostRecentMessage = true
        navigationController?.navigationBar.topItem?.title = "5Friends"
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
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, sender: String!, date: NSDate!) {
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        sendMessage(text, sender: sender)
        
        finishSendingMessage()
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        println("Camera pressed!")
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, bubbleImageViewForItemAtIndexPath indexPath: NSIndexPath!) -> UIImageView! {
        let message = messages[indexPath.item]
        
        if message.sender() == sender {
            return UIImageView(image: outgoingBubbleImageView.image, highlightedImage: outgoingBubbleImageView.highlightedImage)
        }
        
        return UIImageView(image: incomingBubbleImageView.image, highlightedImage: incomingBubbleImageView.highlightedImage)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageViewForItemAtIndexPath indexPath: NSIndexPath!) -> UIImageView! {
        let message = messages[indexPath.item]
        if let avatar = avatars[message.sender()] {
            return UIImageView(image: avatar)
        } else {
            setupAvatarImage(message.sender(), imageUrl: message.imageUrl(), incoming: true)
            return UIImageView(image:avatars[message.sender()])
        }
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        if message.sender() == sender {
            cell.textView.textColor = UIColor.blackColor()
        } else {
            cell.textView.textColor = UIColor.whiteColor()
        }
        
        let attributes : [NSObject:AnyObject] = [NSForegroundColorAttributeName:cell.textView.textColor, NSUnderlineStyleAttributeName: 1]
        cell.textView.linkTextAttributes = attributes
        
        //        cell.textView.linkTextAttributes = [NSForegroundColorAttributeName: cell.textView.textColor,
        //            NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle]
        return cell
    }
    
    
    // View  usernames above bubbles
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item];
        
        // Sent by me, skip
        if message.sender() == sender {
            return nil;
        }
        
        // Same as previous sender, skip
        if indexPath.item > 0 {
            let previousMessage = messages[indexPath.item - 1];
            if previousMessage.sender() == message.sender() {
                return nil;
            }
        }
        
        return NSAttributedString(string:message.sender())
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let message = messages[indexPath.item]
        
        // Sent by me, skip
        if message.sender() == sender {
            return CGFloat(0.0);
        }
        
        // Same as previous sender, skip
        if indexPath.item > 0 {
            let previousMessage = messages[indexPath.item - 1];
            if previousMessage.sender() == message.sender() {
                return CGFloat(0.0);
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
}

