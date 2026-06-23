//
//  PushNetworking.swift
//  EgoiPushLibrary
//
//  Created by João Silva on 15/01/2021.
//

final class PushNetworking {
    
    /// Sent the token to server with the saved configuration
    /// - Parameters:
    ///   - field: the field to the two steps validation
    ///   - value: the value for that field
    ///   - token: the device token (string)
    ///   - callback: the success result of the request
    static func sendToken(
        field: String?,
        value: String?,
        token: String,
        callback: @escaping (_ success: Bool) -> Void
    ) {
        guard let (appId, apiKey, userAgent) = NetworkUtils.retrieveAuthenticationData() else {
            callback(false)
            return
        }
        
        let json: NSMutableDictionary = [
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
            apiKey: apiKey,
            endPoint: "\(Endpoints.endPoint)\(appId)\(Endpoints.register)",
            method: .POST,
            userAgent: userAgent,
            json: json)
        
        request.send { (data) in
            
            guard let dictionary = NetworkUtils.desirializeData(data: data) else {
                DispatchQueue.main.async {
                    callback(false)
                }
                return
            }
            
            guard let result = dictionary.object(forKey: "success") as? Bool else {
                DispatchQueue.main.async {
                    callback(false)
                }
                return
            }
            
            DispatchQueue.main.async {
                callback(result == true)
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
    ///   - contactId: the current contact id (related to the E-Goi message)
    ///   - messageHash: the message hash (E-Goi internal)
    ///   - event: the event to send to the server
    ///   - callback: the callback
    static func sendEvent(
        contactId: String,
        messageHash: String,
        mailingId: Int,
        event: String,
        callback: @escaping (_ success: Bool) -> Void
    ) {
        guard let (appId, apiKey, userAgent) = NetworkUtils.retrieveAuthenticationData() else {
            callback(false)
            return
        }
        
        guard !contactId.isEmpty else {
            print("The contact ID cannot be empty.")
            callback(false)
            return
        }
        
        let json: NSMutableDictionary = [
            "contact": contactId,
            "os": "ios",
            "message_hash": messageHash,
            "mailing_id": mailingId,
            "event": event
        ]
        
        let request = NetworkRequest(
            apiKey: apiKey,
            endPoint: Endpoints.endPoint + appId + Endpoints.event,
            method: .POST,
            userAgent: userAgent,
            json: json
        )
        
        request.send { (data) in
            guard let dictionary = NetworkUtils.desirializeData(data: data) else {
                DispatchQueue.main.async {
                    callback(false)
                }
                
                return
            }
            
            guard let result = dictionary.object(forKey: "success") as? Bool else {
                DispatchQueue.main.async {
                    callback(false)
                }
                
                return
            }
            
            DispatchQueue.main.async {
                callback(result == true)
            }
            
        } failure: { (message) in
            print("Error sending request to server: \(message ?? "---")")
            
            DispatchQueue.main.async {
                callback(false)
            }
        }
    }
}
