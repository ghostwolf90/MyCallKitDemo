
import Foundation
import CallKit

class CallManager {
    static var sharedInstance = CallManager()
    var callsChangedHandler: (() -> Void)?
  
    private(set) var calls = [Call]()
    private let callController = CXCallController()
  
    func startCall(handle: String, videoEnabled: Bool) {
        //一個 CXHandle 對象表示了一次操作，同時指定了操作的類型和值。 App支持對電話號碼進行操作，因此我們在操作中指定了電話號碼。
        let handle = CXHandle(type: .generic, value: handle)
        let startCallAction = CXStartCallAction(call: UUID(), handle: handle)
        startCallAction.isVideo = videoEnabled
        let transaction = CXTransaction(action: startCallAction)

        requestTransaction(transaction)
    }
  
    func end(call: Call) {
        //先創建一個 CXEndCallAction。將通話的 UUID 傳遞給構造函數，以便在後面可以識別通話。
        let endCallAction = CXEndCallAction(call: call.uuid)
        //然後將 action 封裝成 CXTransaction，以便發送給系統。
        let transaction = CXTransaction(action: endCallAction)
    
        requestTransaction(transaction)
    }
  
    func setHeld(call: Call, onHold: Bool) {
        //這個 CXSetHeldCallAction 包含了通話的 UUID 以及保持狀態
        let setHeldCallAction = CXSetHeldCallAction(call: call.uuid, onHold: onHold)
        let transaction = CXTransaction()
        transaction.addAction(setHeldCallAction)
    
        requestTransaction(transaction)
    }
    
    //麥克風靜音
    func setMute(call: Call, muted: Bool) {
        //CXSetMutedCallAction設置麥克風靜音
        let setMuteCallAction = CXSetMutedCallAction(call: call.uuid, muted: muted)
        let transaction = CXTransaction()
        transaction.addAction(setMuteCallAction)
        requestTransaction(transaction)
    }
  
    //呼叫 callController 的 request(_:completion:) 。系統會請求 CXProvider 執行這個 CXTransaction，這會導致你實現的委託方法被調用。
    private func requestTransaction(_ transaction: CXTransaction) {
        callController.request(transaction) { error in
            if let error = error {
                print("Error requesting transaction: \(error)")
            } else {
                print("Requested transaction successfully")
            }
        }
    }
  
    func callWithUUID(uuid: UUID) -> Call? {
        guard let index = calls.firstIndex(where: { $0.uuid == uuid }) else {
            return nil
        }
        return calls[index]
    }

    func add(call: Call) {
        calls.append(call)
        call.stateChanged = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.callsChangedHandler?()
        }
        callsChangedHandler?()
    }

    func remove(call: Call) {
        guard let index = calls.firstIndex(where: { $0 === call }) else { return }
        calls.remove(at: index)
        callsChangedHandler?()
    }
  
    func removeAllCalls() {
        calls.removeAll()
        callsChangedHandler?()
    }
}
