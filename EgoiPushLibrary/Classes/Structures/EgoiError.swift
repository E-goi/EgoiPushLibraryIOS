//
//  EgoiError.swift
//  EgoiPushLibrary
//
//  Created by João Silva on 19/06/2026.
//

import Foundation

internal enum EgoiError: String, Error {
    case missingApiKey = "API key is missing or an empty string"
    case missingAppId = "App ID is missing or an empty string"
}
