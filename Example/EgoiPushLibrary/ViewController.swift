//
//  ViewController.swift
//  EgoiPushLibrary
//
//  Created by João Silva on 01/19/2021.
//  Copyright (c) 2021 João Silva. All rights reserved.
//

import UIKit
import EgoiPushLibrary

class ViewController: UIViewController {
    @IBAction func requestForegroundLocation() {
        EgoiPushLibrary.shared.requestForegroundLocationAccess()
    }
    
    @IBAction func requestBackgroundLocation() {
        EgoiPushLibrary.shared.requestBackgroundLocationAccess()
    }
    
    @IBAction func registerToken() {
        EgoiPushLibrary.shared.sendToken(field: "email", value: "jsilva+iospush@e-goi.com") { result, message in
            print(result)
            
            if let msg = message {
                print(msg)
            }
        }
    }
}

