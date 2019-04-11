//
//  ViewController.swift
//  MyCallKit
//
//  Created by Laibit on 2019/4/3.
//  Copyright © 2019 Laibit. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func IncomingCallPressed(_ sender: UIButton) {
        DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + 3.0) {
            CallkitManager.sharedInstance.displayIncomingCall(uuid: UUID(), handle: "Steve", hasVideo: false) { _ in
            }
        }
    }
    
    @IBAction func startCallPressed(_ sender: UIButton) {
        CallkitManager.sharedInstance.startCall(handle: "Steve", videoEnabled: false)
        
    }
}

