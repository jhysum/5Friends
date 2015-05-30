//
//  AppDelegate.swift
//  5Friends
//
//  Created by Jesse Sum on 5/26/15.
//  Copyright (c) 2015 Jesse Sum. All rights reserved.
//

import UIKit
import Parse

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var badgeNumber = 0


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        Parse.setApplicationId("my62a2VFXihe66Hg6g395tUTEsPHatVw66ukl2M8",
            clientKey: "hFjLcC1j9hOILFimQ5eC5frVamyXrZLVLtoZt0M1")
        
        // Register for Push Notitications
        if application.applicationState != UIApplicationState.Background {
            // Track an app open here if we launch with a push, unless
            // "content_available" was used to trigger a background push (introduced in iOS 7).
            // In that case, we skip tracking here to avoid double counting the app-open.
            
            let preBackgroundPush = !application.respondsToSelector("backgroundRefreshStatus")
            let oldPushHandlerOnly = !self.respondsToSelector("application:didReceiveRemoteNotification:fetchCompletionHandler:")
            var pushPayload = false
            if let options = launchOptions {
                pushPayload = options[UIApplicationLaunchOptionsRemoteNotificationKey] != nil
            }
            if (preBackgroundPush || oldPushHandlerOnly || pushPayload) {
                PFAnalytics.trackAppOpenedWithLaunchOptionsInBackground(launchOptions, block:nil)
            }
        }
        if application.respondsToSelector("registerUserNotificationSettings:") {
            let userNotificationTypes = UIUserNotificationType.Alert | UIUserNotificationType.Badge | UIUserNotificationType.Sound
            let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        } else {
            let types = UIRemoteNotificationType.Badge | UIRemoteNotificationType.Alert | UIRemoteNotificationType.Sound
            application.registerForRemoteNotificationTypes(types)
        }
        
        badgeNumber = 0
        let installation = PFInstallation.currentInstallation()
        installation.badge = badgeNumber
        installation.save()
        
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
        badgeNumber = 0
        let installation = PFInstallation.currentInstallation()
        installation.badge = badgeNumber
        installation.save()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo:NSDictionary) {
        println("Received remote notification (in appDelegate): \(userInfo)")
        // Optionally provide a delegate that will be used to handle notifications received while the app is running
        
        if application.applicationState == UIApplicationState.Inactive {
            badgeNumber = badgeNumber + 1
            let installation = PFInstallation.currentInstallation()
            installation.badge = badgeNumber
            installation.save()
            PFPush.handlePush(userInfo)
            PFAnalytics.trackAppOpenedWithRemoteNotificationPayloadInBackground(userInfo, block: nil)
        } else {
            let installation = PFInstallation.currentInstallation()
            installation.badge = 0
            installation.save()
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: NSDictionary, fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        println("Received remote notification (in appDelegate): \(userInfo)")        
        
        if application.applicationState == UIApplicationState.Inactive {
            badgeNumber = badgeNumber + 1
            let installation = PFInstallation.currentInstallation()
            installation.badge = badgeNumber
            installation.save()
            PFPush.handlePush(userInfo)
            
            PFAnalytics.trackAppOpenedWithRemoteNotificationPayloadInBackground(userInfo, block: nil)
        } else {
            let installation = PFInstallation.currentInstallation()
            installation.badge = 0
            installation.save()
        }
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.save()
        println("Device Token function: \(deviceToken)")
    }
    

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        if error.code == 3010 {
            println("Push notifications are not supported in the iOS Simulator.")
        } else {
            println("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    

}

