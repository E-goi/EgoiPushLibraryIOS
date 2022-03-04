//
//  EGoiMessage.swift
//  EgoiPushLibrary
//
//  Created by João Silva on 15/01/2021.
//

public struct EGoiMessage {
    public init() {}
    public var notification: EGoiMessageNotification = EGoiMessageNotification()
    public var data: EGoiMessageData = EGoiMessageData()
}

public struct EGoiMessageNotification {
    public var title: String?
    public var body: String?
    public var image: String?
}

public struct EGoiMessageData {
    public var os: String = "ios"
    public var messageHash: String?
    public var listId: Int?
    public var contactId: String?
    public var accountId: Int?
    public var applicationId: String?
    public var messageId: Int?
    public var deviceId: Int = 0
    public var geo: EGoiMessageDataGeo = EGoiMessageDataGeo()
    public var actions: EGoiMessageDataAction = EGoiMessageDataAction()
}

public struct EGoiMessageDataGeo {
    public var latitude: Double?
    public var longitude: Double?
    public var radius: Double?
    public var duration: Int?
}

public struct EGoiMessageDataAction {
    public var type: String?
    public var text: String?
    public var url: String?
    public var textCancel: String?
}
