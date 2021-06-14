# What's new in version 2.0.0?

### MAJOR:

#### Notifications are now sent as Remote Notification instead of silent:

Due to some problems with the delivery of the notifications, we changed our logic to start sending the notifications as Remote Notifications (or normal). This 
brings some changes to the configuration of the library. Since the notifications are now displayed by the OS, you must generate a **NotificationServiceExtension** in 
your app to process the image and actions of the notification before showing in the device. To ease the configuration process, you can copy the content of our 
[NotificationService](Example/NotificationService/NotificationService.swift) file and past in yours (just make sure the name of your class is the one you 
generated).

### MINOR:

#### Actions in the notification:

The actions you define in your E-goi campaign, are also displayed in the notification that is sent to the user device.

#### "Cancel" notification / pop-up label:

You no longer need to define a label for the "Cancel" action of the notifications during the configuration of the library.
Now, you define the label on the E-goi platform during the creation of a campaign, and it is inserted automatically on your
notification / pop-up.

#### Geofence duration:

You can now add a duration to the geofence during the creation of Push campaign in the E-goi
platform.

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

**Note:** Your AppDelegate should extend our EgoiAppDelegate instead of the UIResponder, UIApplicationDelegate. If you are using a SceneDelegate, you must also extend ou EgoiSceneDelegate. This is a way for us to process logic so you don't have to, like processing the received remote notifications, and it allows us to display Alerts in your app.

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

This method processes the received remote notification. If the remote notification is a geopush, creates a geofence that triggers a local notification when the user enters teh region. If it is a normal notification, shows the notification and opens a dialog with the actions defined in E-goi when the user opens thr notification banner.

This method is already called inside the didReceiveRemoteNotification implemented in **EgoiAppDelegate.swift**.

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

### Actions

#### EgoiPushLibrary.shared.requestForegroundLocationAccess()

Requests the user permission to access the location when the app is in the foreground (displaying on screen).

#### EgoiPushLibrary.shared.requestBackgroundLocationAccess()

Requests the user permission to access the location when the app is in background (minimized or closed).

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

## Author

E-goi, integrations@e-goi.com

## License

EgoiPushLibrary is available under the MIT license. See the LICENSE file for more info.
