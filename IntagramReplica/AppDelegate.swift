//
//  AppDelegate.swift
//  IntagramReplica
//
//  Created by Harshit Singh on 11/7/17.
//  Copyright © 2017 Harshit Singh. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import FBSDKCoreKit
import UserNotifications
import FirebaseMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert,.sound,.badge]) { (granted, error) in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                print("allowed")
            }
        }
        
//        application.listenForRemoteNotifications()
        
        Messaging.messaging().delegate = self
        Messaging.messaging().shouldEstablishDirectChannel = true
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        let varAvgvalue = String(format: "%@", deviceToken as CVarArg)
        
        let token = varAvgvalue.trimmingCharacters(in: CharacterSet(charactersIn: "<>")).replacingOccurrences(of: " ", with: "")
        
        //print(token)
        Messaging.messaging().apnsToken = deviceToken
        //print(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
    }
    
    var userId: String?
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        
        guard let uid = userInfo["gcm.notification.sender"] as? String else {
            return
        }
        window = UIWindow(frame: UIScreen.main.bounds)
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let mainTabCont = sb.instantiateViewController(withIdentifier: "HomeTabBarController") as? MainTabViewController
        let cont = sb.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController
        cont?.userId = uid
        cont?.fromCont = "AppDelegate"
        
        
        
//        let viewController = self.window?.rootViewController?.storyboard?.instantiateViewController(withIdentifier: "HomeTabBarController") as! MainTabViewController
//        self.window?.rootViewController = viewController
//        var view = UIView(frame: UIScreen.main.bounds)
//        window?.makeKeyAndVisible()
//        var a = MainTabViewController(nibName: <#T##String?#>, bundle: <#T##Bundle?#>)
//        viewController.present(cont!, animated: true, completion: nil)
//        //mainTabCont?.present(cont!, animated: true, completion: nil)
//    }
    
    
//    func push(_ viewController: UIViewController?) {
//        if let pushViewController = viewController {
//            if let presentedController = topViewController() as? UIViewController? {
//                presentedController?.navigationController?.pushViewController(pushViewController, animated: true)
//            }
//        }
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {

        if let dict = remoteMessage.appData as? Dictionary<String,Any>, let from = dict["from"] as? String  {
            print(from)
            //var id = from.substring(from: from.inde)
            //userId = from.substring(from: from.lastIndexOf("topic/")!)
            //userId!.removeFirst()
        }
    }
    
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print(fcmToken)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

extension String {
    func indexOf(_ input: String,
                 options: String.CompareOptions = .literal) -> String.Index? {
        return self.range(of: input, options: options)?.lowerBound
    }
    
    func lastIndexOf(_ input: String) -> String.Index? {
        return indexOf(input, options: .backwards)
    }
}

