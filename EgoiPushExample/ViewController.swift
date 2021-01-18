//
//  ViewController.swift
//  EgoiPushExample
//
//  Created by João Silva on 15/01/2021.
//

import UIKit
import EgoiPushLibrary

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

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

