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
    /// The App Group identifier shared between the main app target and this extension.
    ///
    /// Used as the suite name for `UserDefaults` (to read the API key and app ID written by the host app),
    /// as the `sharedContainerIdentifier` for the background `URLSession`, and as the base path for
    /// payload files written to the App Group container before upload.
    private static let appGroup = "group.com.egoiapp.sdk"
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bac = bestAttemptContent {
            processNotificationContent(bac) { b in
                FIRMessagingExtensionHelper().populateNotificationContent(b, withContentHandler: contentHandler)
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
    private func processNotificationContent(_ bestAttemptContent: UNMutableNotificationContent, callback: @escaping (_ b: UNMutableNotificationContent) -> Void) {
        guard let aps = bestAttemptContent.userInfo["aps"] as? NSDictionary else {
            callback(bestAttemptContent)
            return
        }
        
        // Report delivery to E-goi; safe to force-cast because `aps` was already verified as NSDictionary above.
        self.sendReceivedMetric(data: aps as! [String : Any])
        
        guard let actionsString = aps["actions"] as? String else {
            callback(bestAttemptContent)
            return
        }
        
        if let actions = convertToDictionary(actionsString) {
            if actions["url"] == "" {
                callback(bestAttemptContent)
                return
            }
            
            let confirmAction = UNNotificationAction(identifier: "confirm", title: actions["text"] ?? "", options: UNNotificationActionOptions.foreground)
            let cancelAction = UNNotificationAction(identifier: "close", title: actions["text-cancel"] ?? "", options: UNNotificationActionOptions.destructive)
            
            let categoryIdentifier = aps["message-hash"] as! String
            let category = UNNotificationCategory(identifier: categoryIdentifier, actions: [confirmAction, cancelAction], intentIdentifiers: [], options: .customDismissAction)
            
            bestAttemptContent.categoryIdentifier = categoryIdentifier
            
            UNUserNotificationCenter.current().getNotificationCategories() { cats in
                UNUserNotificationCenter.current().setNotificationCategories(cats.union([category]))
                // This sleep is required to give time for the category to be register in the application before displaying the notification
                usleep(500000)
                callback(bestAttemptContent)
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
    
    /// A lazily-initialized background `URLSession` used to upload notification delivery metrics.
    ///
    /// Configured with a background session identifier scoped to the shared App Group so uploads
    /// can continue after the extension is suspended. `sessionSendsLaunchEvents` is enabled so the
    /// system can relaunch the host app to handle transfer completion, and `sharedContainerIdentifier`
    /// is set so the session can read payload files written to the App Group container.
    private lazy var backgroundSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "\(NotificationService.appGroup).backgroundmetrics")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        config.sharedContainerIdentifier = NotificationService.appGroup
        
        return URLSession(configuration: config, delegate: nil, delegateQueue: nil)
    }()
    
    /// Sends a "received" event metric to the E-goi API when a push notification is delivered.
    ///
    /// Reads the API key and app ID from the shared `UserDefaults` suite, then POSTs a JSON payload
    /// to the E-goi event endpoint via a background `URLSession` upload task. The payload is first
    /// written to the shared App Group container so the upload can survive extension suspension.
    /// Silently exits if required values (API key, app ID, or a non-zero mailing ID) are unavailable.
    ///
    /// - Parameter data: The `aps` dictionary from the notification's `userInfo`, expected to contain
    ///   `"contact-id"`, `"message-hash"`, and `"mailing-id"` keys.
    private func sendReceivedMetric(data: [String: Any]) {
        let sharedDefaults = UserDefaults(suiteName: NotificationService.appGroup)
        
        guard let apiKey = sharedDefaults?.string(forKey: "\(NotificationService.appGroup).apikey") else { return }
        guard let appId = sharedDefaults?.string(forKey: "\(NotificationService.appGroup).appid") else { return }
        guard let mailingId = data["mailing-id"] as? String ?? nil, mailingId != "0" else { return }
        guard let url = URL(string: "https://api.egoiapp.com/push/apps/\(appId)/event") else { return }
        
        let userAgent = sharedDefaults?.string(forKey: "\(NotificationService.appGroup).useragent") ?? "E-goi/Unknown (iOS)"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "ApiKey")
        request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: [
                "contact": data["contact-id"],
                "os": "ios",
                "message_hash": data["message-hash"],
                "mailing_id": Int(mailingId) ?? 0,
                "event": "received"
            ], options: [])
            
            guard let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: NotificationService.appGroup) else {
                print("Failed to find shared App Group container")
                return
            }
            
            let fileUrl = sharedContainerURL.appendingPathComponent("metric_\(UUID().uuidString).json")
            try jsonData.write(to: fileUrl)
            
            let uploadtask = backgroundSession.uploadTask(with: request, fromFile: fileUrl)
            uploadtask.resume()
        } catch {
            print("Failed to serialize or write tracking metrics: \(error)")
        }
    }
}
