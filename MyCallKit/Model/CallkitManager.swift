//
//  CallkitManager.swift
//  MyCallKit
//
//  Created by Laibit on 2019/4/3.
//  Copyright © 2019 Laibit. All rights reserved.
//

import UIKit
import Intents

protocol StartCallConvertible {
    var startCallHandle: String? { get }
    var video: Bool? { get }
}

extension StartCallConvertible {
    var video: Bool? {
        return nil
    }
}

@available(iOS 10.0, *)
protocol SupportedStartCallIntent {
    var contacts: [INPerson]? { get }
}

@available(iOS 10.0, *)
extension INStartAudioCallIntent: SupportedStartCallIntent {}
@available(iOS 10.0, *)
extension INStartVideoCallIntent: SupportedStartCallIntent {}

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

extension NSUserActivity: StartCallConvertible {
    
    var startCallHandle: String? {
        if #available(iOS 10.0, *) {
            guard
                let interaction = interaction,
                let startCallIntent = interaction.intent as? SupportedStartCallIntent,
                let contact = startCallIntent.contacts?.first
                else {
                    return nil
            }
            return contact.personHandle?.value
        }
        
        return nil
    }
    
    var video: Bool? {
        if #available(iOS 10.0, *) {
            guard
                let interaction = interaction,
                let startCallIntent = interaction.intent as? SupportedStartCallIntent
                else {
                    return nil
            }
            
            return startCallIntent is INStartVideoCallIntent
        }
        return nil
    }
}
