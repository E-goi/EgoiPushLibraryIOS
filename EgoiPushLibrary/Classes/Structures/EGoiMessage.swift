//
//  EGoiMessage.swift
//  EgoiPushLibrary
//
//  Created by João Silva on 15/01/2021.
//

struct EGoiMessage {
    var notification: EGoiMessageNotification = EGoiMessageNotification()
    var data: EGoiMessageData = EGoiMessageData()
}

struct EGoiMessageNotification {
    var title: String?
    var body: String?
    var image: String?
}

struct EGoiMessageData {
    var os: String = "ios"
    var messageHash: String?
    var listId: Int?
    var contactId: String?
    var accountId: Int?
    var applicationId: Int?
    var messageId: Int?
    var deviceId: Int = 0
    var geo: EGoiMessageDataGeo = EGoiMessageDataGeo()
    var actions: EGoiMessageDataAction = EGoiMessageDataAction()
}

struct EGoiMessageDataGeo {
    var latitude: Double?
    var longitude: Double?
    var radius: Double?
}

struct EGoiMessageDataAction {
    var type: String?
    var text: String?
    var url: String?
}
