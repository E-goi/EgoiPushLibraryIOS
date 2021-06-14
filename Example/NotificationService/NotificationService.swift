//
//  NotificationService.swift
//  NotificationService
//
//  Created by João Silva on 14/04/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UserNotifications
import Firebase

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if var bac = bestAttemptContent {
            processNotificationContent(&bac) {
                FIRMessagingExtensionHelper().populateNotificationContent(bac, withContentHandler: contentHandler)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    // MARK: - Notification Actions
    
    // Note: It is required to add this code by hand since our SDK uses the property "share" of the "UIApplication"
    // to request notification permissions and register events. This property is not accessible in extensions so Swift
    // does not allow to add our SDK to the extension's target.
    
    /// Creates a temporary notification category with the actions defined on your E-goi campaign and adds it to the notification that's going to be presented.
    /// When the notification is opened or dismissed, the category is deleted from the application.
    private func processNotificationContent(_ bestAttemptContent: inout UNMutableNotificationContent, callback: @escaping () -> Void) {
        guard let aps = bestAttemptContent.userInfo["aps"] as? NSDictionary else {
            return
        }
        
        guard let actionsString = aps["actions"] as? String else {
            return
        }
        
        if let actions = convertToDictionary(actionsString) {
            let confirmAction = UNNotificationAction(identifier: "confirm", title: actions["text"] ?? "", options: UNNotificationActionOptions.foreground)
            let cancelAction = UNNotificationAction(identifier: "close", title: actions["text-cancel"] ?? "", options: UNNotificationActionOptions.destructive)
            
            let categoryIdentifier = aps["message-hash"] as! String
            let category = UNNotificationCategory(identifier: categoryIdentifier, actions: [confirmAction, cancelAction], intentIdentifiers: [], options: UNNotificationCategoryOptions.customDismissAction)
            
            bestAttemptContent.categoryIdentifier = categoryIdentifier
            
            UNUserNotificationCenter.current().getNotificationCategories() { cats in
                UNUserNotificationCenter.current().setNotificationCategories(cats.union([category]))
                // This sleep is required to give time for the category to be register in the application before displaying the notification
                usleep(500000)
                callback()
            }
        }
    }
    
    /// Converts a JSON string to an Dictionary
    private func convertToDictionary(_ text: String) -> [String: String]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
            } catch {
                print(error.localizedDescription)
            }
        }
        
        return nil
    }
}
