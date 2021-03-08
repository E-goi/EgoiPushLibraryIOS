//
//  AppDelegate.swift
//  EgoiPushLibrary
//
//  Created by João Silva on 01/19/2021.
//  Copyright (c) 2021 João Silva. All rights reserved.
//

import UIKit
import EgoiPushLibrary
import Firebase

@UIApplicationMain
class AppDelegate: EgoiAppDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        EgoiPushLibrary.shared.config(
            appId: "abc",
            apiKey: "abc",
            deepLinkCallBack: { link in
                
            }
                
        )
        
        return true
    }
}

extension AppDelegate : MessagingDelegate {
    
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
