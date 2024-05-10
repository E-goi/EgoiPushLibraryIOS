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
}
