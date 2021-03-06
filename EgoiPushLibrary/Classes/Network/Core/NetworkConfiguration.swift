//
//  NetworkConfiguration.swift
//  EgoiPushLibrary
//
//  Created by João Silva on 15/01/2021.
//

// General callbacks
typealias FailureBlock = (_ message: String?) -> Void
typealias SuccessBlock = (_ data: Data) -> Void

// Http Methods
public enum HttpMethod: String {
    case GET, POST, PUT, DELETE
}

// Event type for push
enum EventType: String {
    case OPEN = "open"
    case CLOSE = "canceled"
}

// Configuration for request
struct RequestValues {
    
    static let timeOut: TimeInterval = 30.0
    static let authorizationHeader = "Authorization"
    static let contentTypeHeader = "Content-Type"
    static let contentTypeJsonValue = "application/json"
    static let contentTypeWwwForm = "application/x-www-form-urlencoded"
    static let contentAccept = "Accept"
}

// Endpoints
struct Endpoints {
    private static let endPoint = "https://push-wrapper.egoiapp.com/"
    static let register = endPoint + "token"
    static let event = endPoint + "event"
}
