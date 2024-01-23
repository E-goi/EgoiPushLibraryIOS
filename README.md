# What's new in version 2.3.2?

### MINOR

#### Notification payload

Added mailing_id to event payload request to add more detail into subscriber activity when they receive a push notification

# EgoiPushLibrary

[![Version](https://img.shields.io/cocoapods/v/EgoiPushLibrary.svg?style=flat)](https://cocoapods.org/pods/EgoiPushLibrary)
[![License](https://img.shields.io/cocoapods/l/EgoiPushLibrary.svg?style=flat)](https://cocoapods.org/pods/EgoiPushLibrary)
[![Platform](https://img.shields.io/cocoapods/p/EgoiPushLibrary.svg?style=flat)](https://cocoapods.org/pods/EgoiPushLibrary)

## Requirements

To use this library you must have Firebase configured in your app. [Don't know how to do it? Read this article](https://firebase.google.com/docs/cloud-messaging/ios/client).
<br><small><b>Note:</b> Since the main objective of this library is to handle push notifications, the only Pod that is required for it to work is `pod 'Firebase/Messaging'`.</small>

You must have an APNs key inserted on the Firebase App. [Read more here](https://firebase.google.com/docs/cloud-messaging/ios/certs).

You must have an [E-goi account](https://login.egoiapp.com/signup/email) with a [Push application configured](https://helpdesk.e-goi.com/650296-Integrar-o-E-goi-com-a-app-m%C3%B3vel-da-minha-empresa-para-enviar-push).

You must have the following properties inserted in your Info.plist:
* Required background modes
   - App registers for location updates
   - App processes data in the background
   - App downloads content in response to push notifications
* Privacy - Location Always and When In Use Usage Description
* Privacy - Location When In Use Usage Description

## Installation

EgoiPushLibrary is available through [CocoaPods](https://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'EgoiPushLibrary'
```

After installing, you can initialize the library in the **AppDelegate.swift** with following instruction:

**Note:** Your AppDelegate should extend our EgoiAppDelegate instead of the UIResponder, UIApplicationDelegate. If you are using a SceneDelegate, you must also extend ou EgoiSceneDelegate. This is a way for us to process logic, so you don't have to, like processing the received remote notifications, and it allows us to display Alerts in your app.

**Note: If you want to be the one handling the notifications, you should extend our EgoiAppDelegateViewOnly, so we do not take control of the UNUserNotificationCenter.**

```swift
import EgoiPushLibrary

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
            dialogCallBack: { message in
                print(message)
            },
            deepLinkCallBack: { message in
                print(message)
            }
        )
            
        return true
    }
}
```

Still in the **AppDelegate.swift**, you can send the Firebase token to the library with the following code:

```swift
extension AppDelegate : MessagingDelegate {
    
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
```

### NotificationServiceExtension

To display the images and actions defined in your E-goi campaign in the notification, you will need to generate a **NotificationServiceExtension** to process the logic 
before the OS displays it in the device. To do that you can follow the instructions in this [link](https://developer.apple.com/documentation/usernotifications/modifying_content_in_newly_delivered_notifications). 
After generating the file, you can copy and past the content of our [NotificationService](Example/NotificationService/NotificationService.swift) (make sure the class name 
is the one you generated and not the one of our file).

In your [Podfile](Example/Podfile), you will need to add 'Firebase/Messaging' as a dependency of your NotificationServiceExtension.

## References

### Configurations

#### EgoiPushLibrary.shared.config()

Responsible for initializing the library. The call of this method is required.

<table>
<thead>
<tr>
   <th>Property</th>
   <th>Type</th>
   <th>Description</th>
   <th>Required</th>
   <th>Default</th>
</tr>
</thead>
<tbody>
<tr>
   <td>appId</td>
   <td>String</td>
   <td>The ID of the app created on the E-goi account.</td>
   <td>true</td>
   <td>---</td>
</tr>
<tr>
   <td>apiKey</td>
   <td>String</td>
   <td>The API key of your E-goi account.</td>
   <td>true</td>
   <td>---</td>
</tr>
<tr>
   <td>geoEnabled</td>
   <td>Bool</td>
   <td>Flag that enables or disabled location related functionalities.</td>
   <td>false</td>
   <td>true</td>
</tr>
<tr>
   <td>dialogCallBack</td>
   <td>EGoiMessage -> Void</td>
   <td>Callback to be called in the place of the dialog.</td>
   <td>false</td>
   <td>nil</td>
</tr>
<tr>
   <td>deepLinkCallBack</td>
   <td>EGoiMessage -> Void</td>
   <td>Callback to be called when the link of the message is a deeplink</td>
   <td>false</td>
   <td>nil</td>
</tr>
</tbody>
</table>

#### EgoiPushLibrary.shared.addFCMToken()

You should call this method everytime a new Firebase token is generated. The token is saved on the library and, if the user is already registered on your E-goi list, updates the token automatically.

<table>
<thead>
<tr>
   <th>Property</th>
   <th>Type</th>
   <th>Description</th>
   <th>Required</th>
   <th>Default</th>
</tr>
</thead>
<tbody>
<tr>
   <td>token</td>
   <td>String</td>
   <td>The token generated by Firebase.</td>
   <td>true</td>
   <td>---</td>
</tr>
</tbody>
</table>

#### EgoiPushLibrary.shared.processNotification()

This method processes the received remote notification. If the remote notification is a geopush, creates a geofence that triggers a local notification when the user enters the region. If it is a normal notification, shows the notification and opens a dialog with the actions defined in E-goi when the user opens the notification banner.

This method is already called inside the didReceiveRemoteNotification implemented in **EgoiAppDelegate.swift** but you can call it if you are the one processing the notification.

<table>
<thead>
<tr>
   <th>Property</th>
   <th>Type</th>
   <th>Description</th>
   <th>Required</th>
   <th>Default</th>
</tr>
</thead>
<tbody>
<tr>
   <td>userInfo</td>
   <td>[AnyHashable : Any]</td>
   <td>The data of the notification.</td>
   <td>true</td>
   <td>---</td>
</tr>
<tr>
   <td>callback</td>
   <td>@escaping (UIBackgroundFetchResult) -> Void</td>
   <td>The callback that will be called when the processing of the notification is finished.</td>
   <td>true</td>
   <td>---</td>
</tr>
</tbody>
</table>

#### EgoiPushLibrary.shared.handleNotificationInteraction()

This method handles the interaction of the user with the notification. If the user clicks the notification, open the app and launch a dialog with actions defined. If the user clicks on the "see" action, open the url defined on the notification in the default browser or tries to call the deeplinkCallback defined in the SDK configs. It also sends the event "open" or "canceled" to E-goi depending on the interaction of the user. 

If you are the one handling the notifications, you should invoke this method inside the didReceive method of the UNUserNotificationCenterDelegate.

<table>
<thead>
<tr>
   <th>Property</th>
   <th>Type</th>
   <th>Description</th>
   <th>Required</th>
   <th>Default</th>
</tr>
</thead>
<tbody>
<tr>
   <td>response</td>
   <td>UNNotificationResponse</td>
   <td>The interaction the user made with the notification</td>
   <td>true</td>
   <td>---</td>
</tr>
<tr>
   <td>userNotificationCenter</td>
   <td>UNUserNotificationCenter</td>
   <td>The current UNUserNotificationCenter instance. It is used to manage the notification categories created by E-goi.</td>
   <td>false</td>
   <td>nil</td>
</tr>
<tr>
   <td>completionHandler</td>
   <td>() -> Void</td>
   <td>The callback to invoke after processing the interaction.</td>
   <td>false</td>
   <td>nil</td>
</tr>
</tbody>
</table>

### Actions

#### EgoiPushLibrary.shared.requestForegroundLocationAccess()

Requests the user permission to access the location when the app is in the foreground (displaying on screen).

#### EgoiPushLibrary.shared.requestBackgroundLocationAccess()

Requests the user permission to access the location when the app is in background (minimized or closed).

#### EgoiPushLibrary.shared.requestNotificationsPermission()

Requests the user permission to send push notifications.

#### EgoiPushLibrary.shared.sendToken()

Registers the Firebase token on the E-goi list. You only need to call this method once, after that, the library automatically updates the E-goi's list contact with the new tokens.

<table>
<thead>
<tr>
   <th>Property</th>
   <th>Type</th>
   <th>Description</th>
   <th>Required</th>
   <th>Default</th>
</tr>
</thead>
<tbody>
<tr>
   <td>field</td>
   <td>String</td>
   <td>The field on the list that will be used to register the token.</td>
   <td>false</td>
   <td>nil</td>
</tr>
<tr>
   <td>value</td>
   <td>String</td>
   <td>The value that will be used to register on the field defined above.</td>
   <td>false</td>
   <td>nil</td>
</tr>
<tr>
   <td>callback</td>
   <td>@escaping (_ success: Bool, _ message: String?) -> Void</td>
   <td>The callback that will be called when the E-goi's server finishes processing the request</td>
   <td>true</td>
   <td>---</td>
</tr>
</tbody>
</table>

#### EgoiPushLibrary.shared.registerEvent()

Register an event related to a notification in E-goi.

<table>
<thead>
<tr>
   <th>Property</th>
   <th>Type</th>
   <th>Description</th>
   <th>Required</th>
   <th>Default</th>
</tr>
</thead>
<tbody>
<tr>
   <td>event</td>
   <td>String</td>
   <td>The event to register in E-goi.</td>
   <td>true</td>
   <td>---</td>
</tr>
<tr>
   <td>message</td>
   <td>EGoiMessage</td>
   <td>The message associated to the event</td>
   <td>true</td>
   <td>---</td>
</tr>
</tbody>
</table>

## Author

E-goi, integrations@e-goi.com

## License

EgoiPushLibrary is available under the MIT license. See the LICENSE file for more info.
