//
//  NetworkUtils.swift
//  EgoiPushLibrary
//
//  Created by João Silva on 15/01/2021.
//
import Foundation

final class NetworkUtils {

    /// Convert NSDictionary to Data
    ///
    /// - Parameter json: the dictionary
    /// - Returns: the data
    static func serializeJson(json: NSDictionary) -> Data? {
        
        do {
            return try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        } catch {
            return nil
        }
    }
    
    /// Convert Data to NSDictionary
    ///
    /// - Parameter data: the data object
    /// - Returns: the dictionary or nil, case fails
    static func desirializeData(data: Data) -> NSDictionary? {
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .init(rawValue: 0))
            
            guard let responseJSON = (json as? NSDictionary) else {
                return nil
            }
            
            return responseJSON
        } catch {
            return nil
        }
    }
    
    static func retrieveAuthenticationData() -> (appId: String, apiKey: String, userAgent: String)? {
        let sharedDefaults = UserDefaults(suiteName: EgoiPushLibrary.appGroup)
        
        guard let appId = sharedDefaults?.string(forKey: "\(EgoiPushLibrary.appGroup).\(EgoiConstant.appIdField.rawValue)") else {
            print(EgoiError.missingAppId.rawValue)
            return nil
        }
        
        guard let apiKey = sharedDefaults?.string(forKey: "\(EgoiPushLibrary.appGroup).\(EgoiConstant.apiKeyField.rawValue)") else {
            print(EgoiError.missingAppId.rawValue)
            return nil
        }
        
        let userAgent = sharedDefaults?.string(forKey: "\(EgoiPushLibrary.appGroup).\(EgoiConstant.userAgentField.rawValue)") ?? "E-goi/Unknown (iOS)"
        
        return (appId, apiKey, userAgent)
    }
}
