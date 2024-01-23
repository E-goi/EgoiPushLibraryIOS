//
//  EGoiMessage.swift
//  EgoiPushLibrary
//
//  Created by João Silva on 15/01/2021.
//

public struct EGoiMessage {
    public var notification: EGoiMessageNotification = EGoiMessageNotification()
    public var data: EGoiMessageData = EGoiMessageData()
    
    public struct EGoiMessageNotification {
        public var title: String = ""
        public var body: String = ""
        public var image: String = ""
    }
    
    public struct EGoiMessageData {
        public var os: String = "ios"
        public var messageHash: String = ""
        public var mailingId: Int = 0
        public var listId: Int = 0
        public var contactId: String = ""
        public var accountId: Int = 0
        public var applicationId: String = ""
        public var messageId: Int = 0
        public var geo: EGoiMessageDataGeo = EGoiMessageDataGeo()
        public var actions: EGoiMessageDataAction = EGoiMessageDataAction()
        
        public struct EGoiMessageDataGeo {
            public var latitude: Double = 0.0
            public var longitude: Double = 0.0
            public var radius: Double = 0.0
            public var duration: Int = 0
            public var periodStart: String? = nil
            public var periodEnd: String? = nil
        }

        public struct EGoiMessageDataAction: Codable {
            public var type: String = ""
            public var text: String = ""
            public var url: String = ""
            public var textCancel: String = ""
            
            private enum CodingKeys: String, CodingKey {
                case type
                case text
                case url
                case textCancel = "text-cancel"
            }
        }
    }

}
