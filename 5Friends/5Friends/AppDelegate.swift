//
//  AppDelegate.swift
//  5Friends
//
//  Created by Jesse Sum on 5/26/15.
//  Copyright (c) 2015 Jesse Sum. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // Register for Push Notitications, if running iOS 8
//        if application.respondsToSelector("registerUserNotificationSettings:") {
//            
//            let types:UIUserNotificationType = (.Alert | .Badge | .Sound)
//            let settings:UIUserNotificationSettings = UIUserNotificationSettings(forTypes: types, categories: nil)
//            
//            application.registerUserNotificationSettings(settings)
//            application.registerForRemoteNotifications()
//            
//        } else {
//            // Register for Push Notifications before iOS 8
//            application.registerForRemoteNotificationTypes(.Alert | .Badge | .Sound)
//        }
        
        // Set log level for debugging config loading (optional)
        // It will be set to the value in the loaded config upon takeOff
        UAirship.setLogLevel(UALogLevel.Trace)
        
        // Populate AirshipConfig.plist with your app's info from https://go.urbanairship.com
        // or set runtime properties here.
        var config:UAConfig = UAConfig.defaultConfig()
        
        // You can then programmatically override the plist values:
        // config.developmentAppKey = "YourKey";
        // etc.
        
        // Call takeOff (which creates the UAirship singleton)
        UAirship.takeOff(config)
        
        // Print out the application configuration for debugging (optional)
        println("Config: \(config.description)");
        
        // Set the icon badge to zero on startup (optional)
        UAirship.push().resetBadge()
        
        // Set the notification types required for the app (optional). This value defaults
        // to badge, alert and sound, so it's only necessary to set it if you want
        // to add or remove types.
        UAirship.push().userNotificationTypes = (UIUserNotificationType.Alert | UIUserNotificationType.Badge | UIUserNotificationType.Sound)

        // User notifications will not be enabled until userPushNotificationsEnabled is
        // set "true" on UAPush. Once enabled, the setting will be persisted and the user
        // will be prompted to allow notifications. You should wait for a more appropriate
        // time to enable push to increase the likelihood that the user will accept
        // notifications.
        UAirship.push().userPushNotificationsEnabled = true
        
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        UAirship.push().resetBadge()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo:NSDictionary) {
        println("Received remote notification (in appDelegate): \(userInfo)")
        // Optionally provide a delegate that will be used to handle notifications received while the app is running
        // UAPush.shared().pushNotificationDelegate = your custom push delegate class conforming to the UAPushNotificationDelegate protocol

        // Reset the badge after a push received (optional)
        UAirship.push().resetBadge()
        
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: NSDictionary, fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        println("Received remote notification (in appDelegate): \(userInfo)")
        // Optionally provide a delegate that will be used to handle notifications received while the app is running
        // UAPush.shared().pushNotificationDelegate = your custom push delegate class conforming to the UAPushNotificationDelegate protocol
        
        // Reset the badge after a push received (optional)
        
        if (application.applicationState != UIApplicationState.Background){
            UAirship.push().resetBadge()
        }
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        println("Device Token functino: \(deviceToken)")
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        println("This is the Error: \(error)")
    }

}

