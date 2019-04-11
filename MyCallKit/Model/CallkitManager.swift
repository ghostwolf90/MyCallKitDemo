//
//  CallkitManager.swift
//  MyCallKit
//
//  Created by Laibit on 2019/4/3.
//  Copyright © 2019 Laibit. All rights reserved.
//

import UIKit

class CallkitManager: NSObject {
    static var sharedInstance = CallkitManager()
    
    var providerDelegate: ProviderDelegate!
    let callManager = CallManager.sharedInstance
    
    func setupCall() {
        providerDelegate = ProviderDelegate(callManager: callManager)
    }
    
    func displayIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((Error?) -> Void)?) {
        providerDelegate.reportIncomingCall(uuid: uuid, handle: handle, hasVideo: hasVideo, completion: completion)
    }
    
    func startCall(handle: String, videoEnabled: Bool) {
        callManager.startCall(handle: handle, videoEnabled: videoEnabled)
    }

}
