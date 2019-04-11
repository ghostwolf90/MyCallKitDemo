//
//  AppDelegate.swift
//  MyCallKit
//
//  Created by Laibit on 2019/4/3.
//  Copyright © 2019 Laibit. All rights reserved.
//

import UIKit
import PushKit
import Intents

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        CallkitManager.sharedInstance.setupCall()
        return true
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
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        guard type == .voIP else {
            print("Callkit& pushRegistry didReceiveIncomingPush But Not VoIP")
            return
        }
        print("Callkit& pushRegistry didReceiveIncomingPush")
        //别忘了在这里加上你们自己接电话的逻辑，比如连接聊天服务器啥的，不然这个电话打不通的
        if let uuidString = payload.dictionaryPayload["UUID"] as? String,
            let handle = payload.dictionaryPayload["handle"] as? String,
            let hasVideo = payload.dictionaryPayload["hasVideo"] as? Bool,
            let uuid = UUID(uuidString: uuidString)
        {
            if #available(iOS 10.0, *) {
                CallkitManager.sharedInstance.displayIncomingCall(uuid: uuid, handle: handle, hasVideo: hasVideo) { (error) in
                    if let e = error {
                        print("CallKit& displayIncomingCall Error \(e)")
                    }
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    //從系統通話記錄中直接撥打App的電話
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if #available(iOS 10.0, *) {
            guard userActivity.startCallHandle != nil else {
                print("Callkit& Could not determine start call handle from user activity: \(userActivity)")
                return false
            }
            
            guard userActivity.video != nil else {
                print("Callkit& Could not determine video from user activity: \(userActivity)")
                return false
            }
            //如果当前有电话，需要根据自己App的业务逻辑判断
            
            //如果没有电话，就打电话，调用自己的打电话方法。
            
            return true
        }
        return false
    }


}

