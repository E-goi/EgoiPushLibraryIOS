//
//  NotificationHandler.swift
//  EgoiPushLibrary
//
//  Created by João Silva on 15/01/2021.
//

import UIKit
import UserNotifications
import CoreLocation

class NotificationHandler {
    var token: String?
    
    var pendingNotifications: [String: EGoiMessage] = [:]
    private var notificationCenterHandler: NotificationCenterHandler?
    
    init() {
        if EgoiPushLibrary.shared.handleNotifications {
            notificationCenterHandler = NotificationCenterHandler(self)
        }
    }
    
    /// Process the remote notification. Validate if it is a geopush and if it is create a geofence, otherwise, fire a notification.
    /// - Parameter userInfo: The data of the remote notification
    func processNotification(userInfo: [AnyHashable: Any]) {
        guard let message = buildMessage(userInfo: userInfo) else {
            return
        }
        
        if message.data.geo.latitude != 0,
           message.data.geo.longitude != 0,
           message.data.geo.radius != 0,
           message.data.messageHash != ""
        {
            EgoiPushLibrary.shared.monitorRegion(
                message.data.geo.latitude,
                message.data.geo.longitude,
                message.data.geo.radius,
                message.data.geo.duration,
                identifier: message.data.messageHash
            )
        }
    }
    
    /// Send a local notification to the user
    /// - Parameter key: The id of the notification saved in the pendingNotifications
    func fireNotification(key: String) {
        guard let message = pendingNotifications[key] else {
            return
        }
        
        let request = createRequest(message: message)
        
        guard let wrapperRequest = request else {
            return
        }
        
        UNUserNotificationCenter.current().add(wrapperRequest) { error in
            if error != nil {
                print(error ?? "Unkown error")
                return
            }
        }
    }
    
    /// Delete a pending notification
    /// - Parameter key: The hash of the notification to be removed
    func deletePendingNotification(key: String) {
        pendingNotifications.removeValue(forKey: key)
    }
    
    // MARK: - Notification handlers
    
    /// Request permission to send push notifications
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error  in
            if let _ = error {
                return
            }
            
            guard granted else {
                return
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func handleNotificationInteraction(
        response: UNNotificationResponse,
        userNotificationCenter: UNUserNotificationCenter? = nil,
        completionHandler: (() -> Void)? = nil
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        var message: EGoiMessage;
        
        if let _ = userInfo["aps"] {
            message = buildMessage(userInfo: userInfo)!
        } else {
            if let key = userInfo["key"] as? String, let msg = pendingNotifications[key] {
                message = msg
                pendingNotifications.removeValue(forKey: key)
            } else {
                return
            }
        }
        
        EgoiPushLibrary.shared.registerEvent(EventType.RECEIVED.rawValue, message: message)
        
        switch response.actionIdentifier {
            case UNNotificationDefaultActionIdentifier:
                if message.data.actions.text != "" && message.data.actions.type != "" && message.data.actions.url != "" && message.data.actions.textCancel != "" {
                    if let callback = EgoiPushLibrary.shared.dialogCallBack {
                        callback(message)
                    } else {
                        fireDialog(message)
                    }
                } else {
                    EgoiPushLibrary.shared.registerEvent(EventType.OPEN.rawValue, message: message)
                }
                break
                    
            case "confirm":
                EgoiPushLibrary.shared.registerEvent(EventType.OPEN.rawValue, message: message)
                
                if message.data.actions.type == "deeplink" {
                    if let callback = EgoiPushLibrary.shared.deepLinkCallBack {
                        callback(message)
                    }
                } else {
                    if message.data.actions.url != "", let url = URL(string: message.data.actions.url) {
                        DispatchQueue.main.async {
                            if UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }
                break
                    
            case "close":
                EgoiPushLibrary.shared.registerEvent(EventType.CLOSE.rawValue, message: message)
                break
                    
            default:
                break
        }
            
        if let unc = userNotificationCenter {
            unc.getNotificationCategories{ cats in
                var categories = cats as Set<UNNotificationCategory>
                categories = categories.filter { $0.identifier != "temp_cat" }
                categories = categories.filter { $0.identifier != message.data.messageHash }
                
                unc.setNotificationCategories(categories)
                
                if let ch = completionHandler {
                    DispatchQueue.main.async {
                        ch()
                    }
                }
            }
        }
    }
    
    // MARK: - Private Functions
    
    /// Build a message with the notification data and add it to the pending notifications map
    /// - Parameter userInfo: The notification data
    /// - Returns: Returns a message
    private func buildMessage(userInfo: [AnyHashable: Any]) -> EGoiMessage? {
        guard let aps = userInfo["aps"] as? NSDictionary else {
            return nil
        }
        
        guard let messageHash = aps["message-hash"] as? String,
              messageHash != ""
        else {
            return nil
        }
        
        var message: EGoiMessage = EGoiMessage()
        message.notification.title = aps["title"] as? String ?? ""
        message.notification.body = aps["body"] as? String ?? ""
        message.notification.image = aps["image"] as? String ?? ""
        
        message.data.messageHash = messageHash
        message.data.mailingId = Int(aps["mailing-id"] as! String) ?? 0
        message.data.listId = Int(aps["list-id"] as! String) ?? 0
        message.data.contactId = aps["contact-id"] as? String ?? ""
        message.data.accountId = Int(aps["account-id"] as! String) ?? 0
        message.data.applicationId = aps["application-id"] as? String ?? ""
        message.data.messageId = Int(aps["message-id"] as! String) ?? 0
        message.data.geo.latitude = Double(aps["latitude"] as! String) ?? 0
        message.data.geo.longitude = Double(aps["longitude"] as! String) ?? 0
        message.data.geo.radius = Double(aps["radius"] as! String) ?? 0
        message.data.geo.duration = Int(aps["duration"] as! String) ?? 0
        message.data.geo.periodStart = aps["time-start"] as? String ?? nil
        message.data.geo.periodEnd = aps["time-end"] as? String ?? nil
        
        if let actionsJson = aps["actions"] as? String, let actions = actionsJson.data(using: .utf8) {
            do {
                message.data.actions = try JSONDecoder().decode(EGoiMessage.EGoiMessageData.EGoiMessageDataAction.self, from: actions)
            } catch {}
        }
        
        pendingNotifications[messageHash] = message
        
        return message
    }
    
    /// Show an alert to the user
    /// - Parameter message: The message to use to create the alert
    private func fireDialog(_ message: EGoiMessage) {
        let alert = UIAlertController(
            title: message.notification.title,
            message: message.notification.body,
            preferredStyle: .alert
        )
        
        if message.data.actions.type != "",
           message.data.actions.text != "",
           message.data.actions.url != "",
           message.data.actions.textCancel != ""
        {
            let close = UIAlertAction(title: message.data.actions.textCancel, style: .destructive) { _ in
                EgoiPushLibrary.shared.registerEvent(EventType.CLOSE.rawValue, message: message)
            }
            
            alert.addAction(close)
            
            let action = UIAlertAction(title: message.data.actions.text, style: .default) { _ in
                EgoiPushLibrary.shared.registerEvent(EventType.OPEN.rawValue, message: message)
                
                if (message.data.actions.type == "deeplink") {
                    if let callback = EgoiPushLibrary.shared.deepLinkCallBack {
                        callback(message)
                    }
                } else {
                    if let url = URL(string: message.data.actions.url) {
                        DispatchQueue.main.async {
                            if UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }
            }
            
            alert.addAction(action)
        }
        
        DispatchQueue.main.async {
            let rootViewController: UIViewController?
            
            if let delegate = UIApplication.shared.delegate, let window = delegate.window as? UIWindow {
                rootViewController = window.rootViewController
            } else if #available(iOS 13.0, *), let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? UIWindowSceneDelegate, let window = sceneDelegate.window as? UIWindow {
                rootViewController = window.rootViewController
            } else {
                return
            }
            
            if let viewController = rootViewController {
                viewController.present(
                    alert,
                    animated: true,
                    completion: nil
                )
                
                guard message.data.messageHash != "" else {
                    return
                }
                
                self.pendingNotifications.removeValue(forKey: message.data.messageHash)
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }
    
    /// Convert a JSON string to a Dictionary
    /// - Parameter text: The JSON string
    /// - Returns: The dictionary
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
    
    /// Create a notification request
    /// - Parameter message: The message to use to create the requests
    /// - Returns: The request
    private func createRequest(message: EGoiMessage) -> UNNotificationRequest? {
        guard message.data.messageHash != "" else {
            return nil
        }
        
        let content = UNMutableNotificationContent()
        
        content.title = message.notification.title
        content.body = message.notification.body
        content.sound = UNNotificationSound.default
        content.badge = (UIApplication.shared.applicationIconBadgeNumber + 1) as NSNumber
        
        content.userInfo = ["key": message.data.messageHash]
        
        if message.notification.image != "", let url = URL(string: message.notification.image) {
            let group = DispatchGroup()
            group.enter()
            
            DispatchQueue.global(qos: .default).async {
                guard let data = try? Data(contentsOf: url) else {
                    return
                }
                
                guard let attachment = self.saveImage("image.png", data: data, options: nil) else {
                    return
                }

                content.attachments = [attachment]
                group.leave()
            }
            
            group.wait()
        }
        
        if message.data.actions.text != "", message.data.actions.textCancel != "" {
            let confirmAction = UNNotificationAction(identifier: "confirm", title: message.data.actions.text, options: [UNNotificationActionOptions.foreground])
            let cancelAction = UNNotificationAction(identifier: "close", title: message.data.actions.textCancel, options: [UNNotificationActionOptions.destructive])
            
            let category = UNNotificationCategory(identifier: message.data.messageHash, actions: [confirmAction, cancelAction], intentIdentifiers: [], options: UNNotificationCategoryOptions.customDismissAction)
            
            UNUserNotificationCenter.current().getNotificationCategories() { cats in
                UNUserNotificationCenter.current().setNotificationCategories(cats.union([category]))
            }
            
            content.categoryIdentifier = message.data.messageHash
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        return UNNotificationRequest(identifier: message.data.messageHash, content: content, trigger: trigger)
    }
    
    /// Save an image to a temporary directory to show on the notification
    /// - Parameters:
    ///   - identifier: The name with which the file will be saved
    ///   - data: The image data
    ///   - options: UNNotificationAttachment options
    /// - Returns: UNNotificationAttachment
    private func saveImage(_ identifier: String, data: Data, options: [AnyHashable: Any]?) -> UNNotificationAttachment? {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            let fileURL = directory.appendingPathComponent(identifier)
            try data.write(to: fileURL, options: [])
            
            return try UNNotificationAttachment(identifier: identifier, url: fileURL, options: options)
        } catch {}
        
        return nil
    }
}
