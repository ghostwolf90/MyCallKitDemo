
import CallKit
import AVFoundation

class ProviderDelegate: NSObject {
  
    fileprivate let callManager: CallManager
    fileprivate let provider: CXProvider
  
    init(callManager: CallManager) {
        self.callManager = callManager
        //用一個 CXProviderConfiguration 初始化 CXProvider，前者在後面會定義成一個靜態屬性。 CXProviderConfiguration 用於定義通話的行為和能力。
        provider = CXProvider(configuration: type(of: self).providerConfiguration)
        super.init()
        //為了能夠響應來自於 CXProvider 的事件，你需要設置它的委託
        provider.setDelegate(self, queue: nil)
    }
    
    //通過設置CXProviderConfiguration來支持視頻通話、電話號碼處理，並將通話群組的數字限制為 1 個，其實光看屬性名大家也能看得懂吧。
    static var providerConfiguration: CXProviderConfiguration {
        let providerConfiguration = CXProviderConfiguration(localizedName: "Hotline")
    
        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.phoneNumber, .generic]
    
        return providerConfiguration
    }
    
    //這個方法牛逼了，它是用來更新系統電話屬性的。 。
    func callUpdate(handle: String, hasVideo: Bool) -> CXCallUpdate {
        let update = CXCallUpdate()
        update.localizedCallerName = "ParadiseDuo"//這裡是系統通話記錄裡顯示的聯繫人名稱哦。需要顯示什麼按照你們的業務邏輯來。
        update.supportsGrouping = false
        update.supportsHolding = false
        update.remoteHandle = CXHandle(type: .generic, value: handle) //填了聯繫人的名字，怎麼能不填他的handle('電話號碼')呢，具體填什麼，根據你們的業務邏輯來
        update.hasVideo = hasVideo
        return update
    }
  
    func reportIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((Error?) -> Void)?) {
        //準備向系統報告一個 call update 事件，它包含了所有的來電相關的元數據。
        let update = self.callUpdate(handle: handle, hasVideo: hasVideo)
        //呼叫 CXProvider 的reportIcomingCall(with:update:completion:)方法通知系統有來電。
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if error == nil {
                //completion 回調會在系統處理來電時呼叫。如果沒有任何錯誤，你就創建一個 Call 實例，將它添加到 CallManager 的通話列表。
                let call = Call(uuid: uuid, handle: handle)
                self.callManager.add(call: call)
            }
            //呼叫 completion，如果它不為空的話。
            completion?(error)
        }
    }
}

// MARK: - CXProviderDelegate

extension ProviderDelegate: CXProviderDelegate {
    //CXProviderDelegate 唯一一個必須實現的代理方法！ ！當 CXProvider 被 reset 時，這個方法被呼叫，這樣你的 App 就可以清空所有去電，會到干淨的狀態。在這個方法中，你會停止所有的呼出音頻會話，然後拋棄所有激活的通話。
    func providerDidReset(_ provider: CXProvider) {
        stopAudio()
    
        for call in callManager.calls {
            call.end()
        }
        callManager.removeAllCalls()
        //這裡添加你們掛斷電話或拋棄所有激活的通話的代碼。 。
    }
  
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        //從 callManager 中獲得一個引用，UUID 指定為要接聽的動畫的 UUID。
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        //設置通話要用的 audio session 是 App 的責任。系統會以一個較高的優先級來激活這個 session。
        configureAudioSession()
        //通過呼叫 answer，你會表明這個通話現在激活
        call.answer()
        //在這裡添加自己App接電話的邏輯
        
        //在處理一個 CXAction 時，重要的一點是，要么你拒絕它（fail），要么滿足它（fullfill)。如果處理過程中沒有發生錯誤，你可以呼叫 fullfill() 表示成功。
        action.fulfill()
    }
  
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        //從 callManager 獲得一個 call 對象。
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        //當 call 即將結束時，停止這次通話的音頻處理。
        stopAudio()
        //呼叫 end() 方法修改本次通話的狀態，以允許其他類和新的狀態交互。
        call.end()
        //在這裡添加自己App掛斷電話的邏輯
        //將 action 標記為 fulfill。
        action.fulfill()
        //當你不再需要這個通話時，可以讓 callManager 回收它。
        callManager.remove(call: call)
    }
  
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        //獲得 CXCall 對象之後，我們要根據 action 的 isOnHold 屬性來設置它的 state。
        call.state = action.isOnHold ? .held : .active
        //根據狀態的不同，分別進行啟動或停止音頻會話。
        if call.state == .held {
            stopAudio()
        } else {
            startAudio()
        }
        //在這裡添加你們自己的通話劉保留邏輯
        action.fulfill()
    }
  
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        //向系統通訊錄更新通話記錄
        let update = self.callUpdate(handle: action.handle.value, hasVideo: action.isVideo)
        provider.reportCall(with: action.callUUID, updated: update)
        
        let call = Call(uuid: action.callUUID, outgoing: true, handle: action.handle.value)
        //當我們用 UUID 創建出 Call 對象之後，我們就應該去配置 App 的音頻會話。和呼入通話一樣，你的唯一任務就是配置。真正的處理在後面進行，也就是在 provider(_:didActivate) 委託方法被呼叫時
        configureAudioSession()
        
        //delegate 會監聽通話的生命週期。它首先會會報告的就是呼出通話開始連接。當通話最終連上時，delegate 也會被通知。
        call.connectedStateChanged = { [weak self] in
            guard let strongSelf = self else { return }
      
            if case .pending = call.connectedState {
                strongSelf.provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: nil)
            } else if case .complete = call.connectedState {
                strongSelf.provider.reportOutgoingCall(with: call.uuid, connectedAt: nil)
            }
        }
    
        //呼叫 call.start() 方法會導致 call 的生命週期變化。如果連接成功，則標記 action 為 fullfill。
        call.start { [weak self] success in
            guard let strongSelf = self else { return }
      
            if success {
                //這裡填寫你們App內打電話的邏輯。 。
                strongSelf.callManager.add(call: call)
                //所有的Action只有呼叫了fulfill()之後才算執行完畢。
                action.fulfill()
            } else {
                action.fail()
            }
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        //獲得 CXCall 對象之後，我們要根據 action 的 ismuted 屬性來設置它的 state。
        call.state = action.isMuted ? .muted : .active
        //在這裡添加你們自己的麥克風靜音邏輯
        action.fulfill()
    }
  
    //當系統激活 CXProvider 的 audio session時，委託會被呼叫。這給你一個機會開始處理通話的音頻。
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        startAudio() ////一定要記得播放鈴聲吶。 。
    }
}
