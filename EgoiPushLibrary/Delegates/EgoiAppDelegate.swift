//
//  PushDelegate.swift
//  EGoiLibrary
//
//  Created by João Silva on 11/01/2021.
//

import UIKit
import Firebase

open class EgoiAppDelegate: UIResponder, UIApplicationDelegate {
    public var window: UIWindow?
    
    /// Initiate the Firebase library
    /// - Parameters:
    ///   - application: Current instance of the application
    ///   - launchOptions: Launch options
    /// - Returns: Status
    public func application(
        _ application: UIApplication,
        willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        return true
    }
    
    /// Handle remote notifications received
    /// - Parameters:
    ///   - application: Current instance of the aplication
    ///   - userInfo: Data of the notification
    ///   - completionHandler: Function callback
    public func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        EgoiPushLibrary.shared.processNotification(userInfo) { result in
            completionHandler(result)
        }
    }
}

extension EgoiAppDelegate : MessagingDelegate {
    
    /// Receive the token from Firebase and save it in the library
    /// - Parameters:
    ///   - messaging: Current instance of the Firebase Messaging module
    ///   - fcmToken: The Firebase token
    public func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        guard let token = fcmToken else {
            return
        }
        
        EgoiPushLibrary.shared.addFCMToken(token: token)
    }
}
