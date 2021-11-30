//
//  EgoiAppDelegateViewOnly.swift
//  EgoiPushLibrary
//
//  Created by João Silva on 29/11/2021.
//

import UIKit

open class EgoiAppDelegateViewOnly: UIResponder, UIApplicationDelegate {
    public var window: UIWindow?
    
    override init() {
        super.init()
        
        EgoiPushLibrary.shared.handleNotifications = false
    }
}
