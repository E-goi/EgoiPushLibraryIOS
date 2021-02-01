//
//  PushNetworking.swift
//  EgoiPushLibrary
//
//  Created by João Silva on 15/01/2021.
//

final class PushNetworking {
    
    /// Sent the token to server with the saved configuration
    /// - Parameters:
    ///   - appId: the app id
    ///   - apiKey: the client apiu key
    ///   - field: the field to the two steps validation
    ///   - value: the value for that field
    ///   - token: the device token (string)
    ///   - callback: the success result of the request
    static func sendToken(
        appId: String,
        apiKey: String,
        field: String?,
        value: String?,
        token: String,
        callback: @escaping (_ success: Bool) -> Void) {
        
        let json: NSMutableDictionary = [
            "api_key": apiKey,
            "app_id": appId,
            "token": token,
            "os": "ios"
        ]
        
        if let wrappedField = field, let wrappedValue = value {
            json.addEntries(from:
                                ["two_steps_data": [
                                    "field": wrappedField,
                                    "value": wrappedValue ]])
        }
        
        let request = NetworkRequest(
            endPoint: Endpoints.register,
            method: .POST,
            json: json)
        
        request.send { (data) in
            
            guard let dictionary = NetworkUtils.desirializeData(data: data) else {
                DispatchQueue.main.async {
                    callback(false)
                }
                return
            }
            
            guard let result = dictionary.object(forKey: "data") as? String else {
                DispatchQueue.main.async {
                    callback(false)
                }
                return
            }
            
            DispatchQueue.main.async {
                callback(result.uppercased() == "OK")
            }
            
        } failure: { (message) in
            
            print("Error sending token to server: \(message ?? "---")")
            
            DispatchQueue.main.async {
                callback(false)
            }
        }
    }
    
    /// Send an event related to the push handling to the server
    /// - Parameters:
    ///   - appId: the client app id
    ///   - apiKey: the client api key
    ///   - contactID: the current contact id (related to the E-Goi message)
    ///   - messageHash: the message hash (E-Goi internal)
    ///   - deviceId: the current device id
    ///   - event: the event to send to the server
    ///   - callback: the callback
    static func sendEvent(
        appId: String,
        apiKey: String,
        contactID: String,
        messageHash: String,
        deviceId: Int,
        event: String,
        callback: @escaping (_ success: Bool) -> Void
    ) {
        let json: NSMutableDictionary = [
            "api_key": apiKey,
            "app_id": appId,
            "contact": contactID,
            "os": "ios",
            "message_hash": messageHash,
            "event": event,
            "device_id": deviceId
        ]
        
        let request = NetworkRequest(
            endPoint: Endpoints.event,
            method: .POST,
            json: json
        )
        
        request.send { (data) in
            guard let dictionary = NetworkUtils.desirializeData(data: data) else {
                DispatchQueue.main.async {
                    callback(false)
                }
                
                return
            }
            
            guard let result = dictionary.object(forKey: "data") as? String else {
                DispatchQueue.main.async {
                    callback(false)
                }
                
                return
            }
            
            DispatchQueue.main.async {
                callback(result.uppercased() == "OK")
            }
            
        } failure: { (message) in
            print("Error sending token to server: \(message ?? "---")")
            
            DispatchQueue.main.async {
                callback(false)
            }
        }
    }
}
