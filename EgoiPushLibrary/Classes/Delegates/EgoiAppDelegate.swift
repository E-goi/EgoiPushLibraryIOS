//
//  PushDelegate.swift
//  EGoiLibrary
//
//  Created by João Silva on 11/01/2021.
//

import UIKit

open class EgoiAppDelegate: UIResponder, UIApplicationDelegate {
    public var window: UIWindow?
    
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
