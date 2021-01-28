//
//  NotificationHandler.swift
//  EgoiPushLibrary
//
//  Created by João Silva on 15/01/2021.
//

import UIKit
import UserNotifications
import CoreLocation

class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    var token: String?
    
    private let userNotificationCenter = UNUserNotificationCenter.current()
    private let pendingNotifications = NSMutableDictionary()
    
    override init() {
        super.init()
        userNotificationCenter.delegate = self
        
        requestPermission()
    }
    
    /// Process the remote notification. Validate if it is a geopush and if it is create a geofence, otherwise, fire a notification.
    /// - Parameter userInfo: The data of the remote notification
    func processNotification(userInfo: [AnyHashable: Any]) {
        let message: EGoiMessage = buildMessage(userInfo: userInfo)
        
        if let _ = message.data.geo.latitude,
           let _ = message.data.geo.longitude,
           let _ = message.data.geo.radius,
           EgoiPushLibrary.shared.isMonitoringAvailable()
        {
            EgoiPushLibrary.shared.createGeofence(message: message)
        } else {
            guard let key = message.data.messageHash else {
                return
            }
            
            fireNotification(key: key)
        }
    }
    
    /// Send a local notification to the user
    /// - Parameter key: The id of the notification saved in the pendingNotifications
    func fireNotification(key: String) {
        guard let message = pendingNotifications[key] as? EGoiMessage else {
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
    
    // MARK: - Notification handlers
    
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
        guard let key = notification.request.content.userInfo["key"] as? String else {
            return
        }
        
        guard let message = pendingNotifications[key] as? EGoiMessage else {
            return
        }
        
        fireDialog(message)
        
        completionHandler([UNNotificationPresentationOptions.sound])
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
        let userInfo = response.notification.request.content.userInfo
        
        guard let key = userInfo["key"] as? String else {
            return
        }
        
        guard let message = pendingNotifications[key] as? EGoiMessage else {
            return
        }
        
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            fireDialog(message)
            break
            
        default:
            break
        }
        
        pendingNotifications.removeObject(forKey: key)
        
        completionHandler()
    }
    
    // MARK: - Private Functions
    
    /// Request permission to send push notifications
    private func requestPermission() {
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
    
    /// Build a message with the notification data and add it to the pending notifications map
    /// - Parameter userInfo: The notification data
    /// - Returns: Returns a message
    private func buildMessage(userInfo: [AnyHashable: Any]) -> EGoiMessage {
        var message = EGoiMessage()
        
        message.notification.title = userInfo["title"] as? String ?? ""
        message.notification.body = userInfo["body"] as? String ?? ""
        message.notification.image = userInfo["image"] as? String
        message.data.messageHash = userInfo["message-hash"] as? String
        
        if let listId = userInfo["list-id"] as? String {
            message.data.listId = Int(listId)
        }
        
        message.data.contactId = userInfo["contact-id"] as? String
        
        if let accountId = userInfo["account-id"] as? String {
            message.data.accountId = Int(accountId)
        }
        
        if let applicationId = userInfo["application-id"] as? String {
            message.data.applicationId = Int(applicationId)
        }
        
        if let messageId = userInfo["message-id"] as? String {
            message.data.messageId = Int(messageId)
        }
        
        if let deviceId = userInfo["device-id"] as? String {
            message.data.deviceId = Int(deviceId) ?? 0
        }
        
        if let latitude = userInfo["latitude"] as? String, let longitude = userInfo["longitude"] as? String, let radius = userInfo["radius"] as? String {
            message.data.geo.latitude = Double(latitude)
            message.data.geo.longitude = Double(longitude)
            message.data.geo.radius = Double(radius)
        }
        
        if let actions = userInfo["actions"] as? String {
            let dict = convertToDictionary(actions)
            
            if let data = dict {
                message.data.actions.type = data["type"]
                message.data.actions.text = data["text"]
                message.data.actions.url = data["url"]
            }
        }
        
        pendingNotifications.setValue(message, forKey: message.data.messageHash!)
        
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
        
        let close = UIAlertAction(
            title: EgoiPushLibrary.shared.dialogCloseLabel,
            style: .destructive,
            handler: { _ in
                EgoiPushLibrary.shared.sendEvent(EventType.CLOSE.rawValue, message: message)
            }
        )
        
        alert.addAction(close)
        
        if let type = message.data.actions.type, let text = message.data.actions.text, let url = message.data.actions.url {
            let action = UIAlertAction(
                title: text,
                style: .default,
                handler: { _ in
                    EgoiPushLibrary.shared.sendEvent(EventType.OPEN.rawValue, message: message)
                    
                    if (type == "deeplink") {
                        if let callback = EgoiPushLibrary.shared.deepLinkCallBack, let link = message.data.actions.url {
                            callback(link)
                        }
                    } else {
                        if let url = URL(string: url) {
                            DispatchQueue.main.async {
                                if UIApplication.shared.canOpenURL(url) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }
                }
            )
            
            alert.addAction(action)
        }
        
        DispatchQueue.main.async {
            let rootViewController: UIViewController?
            
            if let delegate = UIApplication.shared.delegate as? EgoiAppDelegate, let window = delegate.window {
                rootViewController = window.rootViewController
            } else if #available(iOS 13.0, *), let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? EgoiSceneDelegate, let window = sceneDelegate.window {
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
                
                guard let key = message.data.messageHash else {
                    return
                }
                
                self.pendingNotifications.removeObject(forKey: key)
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
        guard let id = message.data.messageHash else {
            return nil
        }
        
        let content = UNMutableNotificationContent()
        
        content.title = message.notification.title ?? ""
        content.body = message.notification.body ?? ""
        content.sound = UNNotificationSound.default
        content.badge = (UIApplication.shared.applicationIconBadgeNumber + 1) as NSNumber
        
        content.userInfo = ["key": message.data.messageHash!]
        
        if let image = message.notification.image {
            guard let data = try? Data(contentsOf: URL(string: image)!) else {
                return nil
            }
            
            guard let attachment = saveImage("image.png", data: data, options: nil) else {
                return nil
            }
            
            content.attachments = [attachment]
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
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
