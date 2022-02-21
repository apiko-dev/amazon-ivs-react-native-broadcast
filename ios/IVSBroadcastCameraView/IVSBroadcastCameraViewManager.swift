import Foundation

@objc (RNIVSBroadcastCameraView)
class IVSBroadcastCameraViewManager: RCTViewManager {
  override func view() -> UIView! {
    return IVSBroadcastCameraView()
  }
  
  override static func requiresMainQueueSetup() -> Bool {
    return true
  }
  
  // Static methods
  @objc public func START(_ node: NSNumber) {
    DispatchQueue.main.async {
      let component = self.bridge.uiManager.view(forReactTag: node) as! IVSBroadcastCameraView
      component.start()
    }
  }
  
  @objc public func STOP(_ node: NSNumber) {
    DispatchQueue.main.async {
      let component = self.bridge.uiManager.view(forReactTag: node) as! IVSBroadcastCameraView
      component.stop()
    }
  }
  
  @objc public func SWAP_CAMERA(_ node:NSNumber) {
    DispatchQueue.main.async {
      let component = self.bridge.uiManager.view(forReactTag: node) as! IVSBroadcastCameraView
      component.swapCamera()
    }
  }
}

