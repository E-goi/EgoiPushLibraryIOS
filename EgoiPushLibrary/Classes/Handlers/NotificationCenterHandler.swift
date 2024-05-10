//
//  NotificationCenterHandler.swift
//  EgoiPushLibrary
//
//  Created by João Silva on 29/11/2021.
//
import Foundation
import UserNotifications

class NotificationCenterHandler: NSObject, UNUserNotificationCenterDelegate {
    private let userNotificationCenter = UNUserNotificationCenter.current()
    
    init(_ notificationHandler: NotificationHandler) {
        super.init()
        userNotificationCenter.delegate = self
        
        notificationHandler.requestPermission()
    }
    
    /// Handle notifications when the app is in foreground
    /// - Parameters:
    ///   - center: The current UNUserNotificationCenter instance
    ///   - notification: The notification received
    ///   - completionHandler: The callback of the function
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([UNNotificationPresentationOptions.alert, UNNotificationPresentationOptions.sound])
    }
    
    /// Handle the interaction of the user with the notification
    /// - Parameters:
    ///   - center: The current UNUserNotificationCenter instance
    ///   - response: The interaction of the user
    ///   - completionHandler: The callback of the function
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        EgoiPushLibrary.shared.handleNotificationInteraction(response: response, userNotificationCenter: userNotificationCenter, completionHandler: completionHandler)
    }
}
