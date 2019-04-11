
import Foundation
import CallKit

class CallManager {
    static var sharedInstance = CallManager()
    var callsChangedHandler: (() -> Void)?
  
    private(set) var calls = [Call]()
    private let callController = CXCallController()
  
    func startCall(handle: String, videoEnabled: Bool) {
        //一个 CXHandle 对象表示了一次操作，同时指定了操作的类型和值。App支持对电话号码进行操作，因此我们在操作中指定了电话号码。
        let handle = CXHandle(type: .generic, value: handle)
        let startCallAction = CXStartCallAction(call: UUID(), handle: handle)
        startCallAction.isVideo = videoEnabled
        let transaction = CXTransaction(action: startCallAction)

        requestTransaction(transaction)
    }
  
    func end(call: Call) {
        let endCallAction = CXEndCallAction(call: call.uuid)
        let transaction = CXTransaction(action: endCallAction)
    
        requestTransaction(transaction)
    }
  
    func setHeld(call: Call, onHold: Bool) {
        let setHeldCallAction = CXSetHeldCallAction(call: call.uuid, onHold: onHold)
        let transaction = CXTransaction()
        transaction.addAction(setHeldCallAction)
    
        requestTransaction(transaction)
    }
  
    //调用 callController 的 request(_:completion:) 。系统会请求 CXProvider 执行这个 CXTransaction，这会导致你实现的委托方法被调用。
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
        guard let index = calls.index(where: { $0.uuid == uuid }) else {
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
        guard let index = calls.index(where: { $0 === call }) else { return }
        calls.remove(at: index)
        callsChangedHandler?()
    }
  
    func removeAllCalls() {
        calls.removeAll()
        callsChangedHandler?()
    }
}
