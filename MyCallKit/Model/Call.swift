import Foundation

enum CallState {
    case connecting
    case active
    case held
    case ended
    case muted
}

enum ConnectedState {
    case pending
    case complete
}

class Call {
  
    let uuid: UUID
    let outgoing: Bool
    let handle: String
  
    var state: CallState = .ended {
        didSet {
            stateChanged?()
        }
    }
  
    var connectedState: ConnectedState = .pending {
        didSet {
            connectedStateChanged?()
        }
    }
  
    var stateChanged: (() -> Void)?
    var connectedStateChanged: (() -> Void)?
  
    init(uuid: UUID, outgoing: Bool = false, handle: String) {
        self.uuid = uuid
        self.outgoing = outgoing
        self.handle = handle
    }
  
    func start(completion: ((_ success: Bool) -> Void)?) {
        completion?(true)

        DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + 3) {
            self.state = .connecting
            self.connectedState = .pending
      
            DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + 1.5) {
                self.state = .active
                self.connectedState = .complete
            }
        }
    }
  
    func answer() {
        state = .active
    }
  
    func end() {
        state = .ended
    }

}
