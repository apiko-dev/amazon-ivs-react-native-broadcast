import AmazonIVSBroadcast
import Foundation

enum BuiltInCameraDeviceUrns: String {
  case backUltraWideCamera = "com.apple.avfoundation.avcapturedevice.built-in_video:5"
  case backCamera = "com.apple.avfoundation.avcapturedevice.built-in_video:0"
  case frontCamera = "com.apple.avfoundation.avcapturedevice.built-in_video:1"
}

// Guide: https://docs.aws.amazon.com/ivs/latest/userguide//broadcast-ios.html
class IVSBroadcastSessionService: NSObject {
  
  private var isInitialized: Bool = false
  private var initialCameraPosition: IVSDevicePosition = IVSDevicePosition.back
  private var currentCameraDeviceUrn: String?
  private var broadcastSession: IVSBroadcastSession?
  private var config = IVSBroadcastConfiguration()
  
  private var onBroadcastError: RCTDirectEventBlock?
  private var onBroadcastAudioStats: RCTDirectEventBlock?
  private var onBroadcastStateChanged: RCTDirectEventBlock?
  private var onBroadcastQualityChanged: RCTDirectEventBlock?
  private var onNetworkHealthChanged: RCTDirectEventBlock?
  
  private func checkBroadcastSessionOrThrow() {
    if (self.broadcastSession == nil || self.isInitialized == false) {
      assertionFailure("Broadcast session is not initialized.")
    }
  }
  
  private func getLogLevel(_ logLevelName: NSString) -> IVSBroadcastSession.LogLevel {
    switch logLevelName {
      case "debug":
        return IVSBroadcastSession.LogLevel.debug
      case "error":
        return IVSBroadcastSession.LogLevel.error
      case "info":
        return IVSBroadcastSession.LogLevel.info
      case "warning":
        return IVSBroadcastSession.LogLevel.warn
      default:
        assertionFailure("Does not support log level: \(logLevelName)")
        return IVSBroadcastSession.LogLevel.error
    }
  }
  
  private func getAspectMode(_ aspectModeName: NSString) -> IVSBroadcastConfiguration.AspectMode {
    switch aspectModeName {
      case "fit":
        return IVSBroadcastConfiguration.AspectMode.fit
      case "fill":
        return IVSBroadcastConfiguration.AspectMode.fill
      case "none":
        return IVSBroadcastConfiguration.AspectMode.none
      default:
        assertionFailure("Does not support aspect mode: \(aspectModeName)")
        return IVSBroadcastConfiguration.AspectMode.fill
    }
  }
  
  private func getCameraPosition(_ cameraPositionName: NSString) -> IVSDevicePosition {
    switch(cameraPositionName) {
      case "front":
        return IVSDevicePosition.front
      case "back":
        return IVSDevicePosition.back
      default:
        assertionFailure("Does not support camera position: \(cameraPositionName)")
        return IVSDevicePosition.back
    }
  }
  
  private func getAudioSessionStrategy(_ audioSessionStrategyName: NSString) -> IVSBroadcastSession.AudioSessionStrategy {
    switch audioSessionStrategyName {
      case "recordOnly":
        return IVSBroadcastSession.AudioSessionStrategy.recordOnly
      case "playAndRecord":
        return IVSBroadcastSession.AudioSessionStrategy.playAndRecord
      case "noAction":
        return IVSBroadcastSession.AudioSessionStrategy.noAction
      default:
        assertionFailure("Does not support audio session strategy: \(audioSessionStrategyName).")
        return IVSBroadcastSession.AudioSessionStrategy.playAndRecord
    }
  }
  
  private func getAudioQuality(_ audioQualityName: NSString) -> IVSBroadcastConfiguration.AudioQuality {
    switch audioQualityName {
      case "minimum":
        return .minimum
      case "low":
        return .low
      case "medium":
        return .medium
      case "high":
        return .high
      case "maximum":
        return .maximum
      default:
        assertionFailure("Does not support audio quality: \(audioQualityName).")
        return .medium
    }
  }
  
  private func getInitialDeviceDescriptors() -> [IVSDeviceDescriptor] {
    switch(self.initialCameraPosition) {
      case .front:
        return IVSPresets.devices().frontCamera()
      default:
        return IVSPresets.devices().backCamera()
    }
  }
  
  private func geDefaultBackCameraUrn() -> String {
    if let defaultBackCameraDescriptor = IVSPresets.devices().backCamera().filter({ $0.type == .camera }).first {
      return defaultBackCameraDescriptor.urn
    }
    return BuiltInCameraDeviceUrns.backCamera.rawValue
  }
  
  private func geDefaultFrontCameraUrn() -> String {
    if let defaultFrontCameraDescriptor = IVSPresets.devices().frontCamera().filter({ $0.type == .camera }).first {
      return defaultFrontCameraDescriptor.urn
    }
    return BuiltInCameraDeviceUrns.frontCamera.rawValue
  }
  
  private func getNextCameraToSwap(_ currentCamera : IVSDevice) -> IVSDeviceDescriptor? {
    let currentCameraPosition = currentCamera.descriptor().position
    
    let foundCamera = IVSBroadcastSession
      .listAvailableDevices()
      .first { $0.type == .camera && $0.urn.contains(currentCameraPosition == IVSDevicePosition.back
                                                     ? self.geDefaultFrontCameraUrn()
                                                     : self.geDefaultBackCameraUrn())}
    
    guard let nextCamera = foundCamera else {
      // NOTE: Defensive code
      return IVSBroadcastSession
        .listAvailableDevices()
        .first { $0.type == .camera && $0.position != currentCameraPosition }
    }
    
    return nextCamera
  }
  
  private func getSessionPreviewView(_ aspectMode: IVSBroadcastConfiguration.AspectMode) -> IVSImagePreviewView? {
    return try? self.broadcastSession?.previewView(with: aspectMode)
  }
  
  public func initiate() throws {
    if self.isInitialized == false {
      do {
        let initialDescriptors = getInitialDeviceDescriptors()
        
        self.broadcastSession = try IVSBroadcastSession(
          configuration: self.config,
          descriptors: initialDescriptors,
          delegate: self
        )
        
        if let initialCameraDeviceDescriptor = initialDescriptors.filter({ $0.type == .camera }).first {
          self.currentCameraDeviceUrn = initialCameraDeviceDescriptor.urn
        }
        
        self.isInitialized = true
      } catch {
        throw IVSBroadcastCameraViewError("Can not initiate IVSBroadcastSessionService. \(error.localizedDescription)")
      }
    }
  }
  
  public func deinitiate() {
    self.checkBroadcastSessionOrThrow()
    
    // If there as an live broadcast when this object deallocates, internally stop will be called during deallocation,
    // and it will block until the stream has been gracefully terminated or a timeout is reeached.
    // Because of that it is recommended that you always explicitly stop a live broadcast before deallocating.
    self.broadcastSession?.stop()
    self.broadcastSession = nil
    self.isInitialized = false
  }
  
  public func isInitiated() -> Bool {
    self.isInitialized
  }
  
  public func isReady() -> Bool {
    guard let isReady = self.broadcastSession?.isReady else {
      return false
    }
    return isReady
  }
  
  public func start(ivsRTMPSUrl: NSString, ivsStreamKey: NSString) throws {
    self.checkBroadcastSessionOrThrow()
    
    do {
      guard let url = URL(string: ivsRTMPSUrl as String) else { throw IVSBroadcastCameraViewError("Can not create a URL instance from the provided ivsRTMPSUrl: \(ivsRTMPSUrl)") }
      try self.broadcastSession?.start(with: url, streamKey: ivsStreamKey as String)
    } catch {
      throw IVSBroadcastCameraViewError("Can not start the configured broadcast session. \(error.localizedDescription)")
    }
  }
  
  public func stop() {
    self.checkBroadcastSessionOrThrow()
    self.broadcastSession?.stop()
  }
  
  public func swapCamera(aspectModeName: NSString, isMirrored: Bool, onReceiveCameraPreview: @escaping (_: Error?, _: IVSImagePreviewView?) -> Void) throws {
    self.checkBroadcastSessionOrThrow()
    
    let currentCameraDeviceUrn = self.currentCameraDeviceUrn ?? ""
    let attachedDevices = self.broadcastSession?.listAttachedDevices()
    let cameras = attachedDevices?.filter { $0.descriptor().urn.contains(currentCameraDeviceUrn) }
    
    guard let currentCamera = cameras?.first else {
      throw IVSBroadcastCameraViewError("Can not get current camera. \(currentCameraDeviceUrn)")
    }
    
    guard let nextCamera = self.getNextCameraToSwap(currentCamera) else {
      throw IVSBroadcastCameraViewError("Can not get next camera to swap.")
    }
    
    self.broadcastSession?.exchangeOldDevice(currentCamera, withNewDevice: nextCamera) { newDevice, _ in
      if let newCameraDevice = newDevice {
        let aspectMode = self.getAspectMode(aspectModeName)
        
        if let newCameraPreview = try? (newCameraDevice as! IVSImageDevice).previewView(with: aspectMode) {
          newCameraPreview.setMirrored(isMirrored)
          onReceiveCameraPreview(nil, newCameraPreview)
        } else {
          onReceiveCameraPreview(IVSBroadcastCameraViewError("Can not get camera preview."), nil)
        }
        
        self.currentCameraDeviceUrn = newCameraDevice.descriptor().urn
      } else {
        onReceiveCameraPreview(IVSBroadcastCameraViewError("New device is empty."), nil)
      }
    }
  }
  
  // Receive camera preview asynchronously to ensure that all devices have been attached
  public func getCameraPreviewAsync(aspectModeName: NSString, isMirrored: Bool, onReceiveCameraPreview: @escaping (_: Error?, _: IVSImagePreviewView?) -> Void) {
    self.checkBroadcastSessionOrThrow()
    
    self.broadcastSession?.awaitDeviceChanges { () -> Void in
      let aspectMode = self.getAspectMode(aspectModeName)
      
      guard let cameraPreview = self.getSessionPreviewView(aspectMode) else {
        onReceiveCameraPreview(IVSBroadcastCameraViewError("Can not get camera preview."), nil)
        return
      }
      
      cameraPreview.setMirrored(isMirrored)
      onReceiveCameraPreview(nil, cameraPreview)
    }
  }
  
  public func setSessionLogLevel(_ logLevel: NSString?) {
    self.checkBroadcastSessionOrThrow()
    
    if let logLevelName = logLevel {
      self.broadcastSession?.logLevel = self.getLogLevel(logLevelName)
    }
  }
  
  public func setLogLevel(_ logLevel: NSString?) {
    if let logLevelName = logLevel {
      self.config.logLevel = self.getLogLevel(logLevelName)
    }
  }
  
  public func setCameraPosition(_ cameraPosition: NSString?) {
    if let cameraPositionName = cameraPosition {
      self.initialCameraPosition = self.getCameraPosition(cameraPositionName)
    }
  }
  
  public func setVideoConfig(_ videoConfig: NSDictionary?) throws {
    guard let videoConfig = videoConfig else { return }
    
    let width = videoConfig["width"]
    let height = videoConfig["height"]
    let bitrate = videoConfig["bitrate"]
    let targetFrameRate = videoConfig["targetFrameRate"]
    let keyframeInterval = videoConfig["keyframeInterval"]
    
    if (width != nil && height != nil && bitrate != nil && targetFrameRate != nil && keyframeInterval != nil) {
      do {
        try self.config.video.setSize(CGSize(width: width as! Int, height: height as! Int))
        try self.config.video.setInitialBitrate(bitrate as! Int)
        try self.config.video.setTargetFramerate(targetFrameRate as! Int)
        try self.config.video.setKeyframeInterval(Float(keyframeInterval as! Int))
        
        if let isBFrames = videoConfig["isBFrames"] {
          self.config.video.usesBFrames = isBFrames as! Bool
        }
        if let isAutoBitrate = videoConfig["isAutoBitrate"] {
          self.config.video.useAutoBitrate = isAutoBitrate as! Bool
        }
        if let maxBitrate = videoConfig["maxBitrate"] {
          try self.config.video.setMaxBitrate(maxBitrate as! Int)
        }
        if let minBitrate = videoConfig["minBitrate"] {
          try self.config.video.setMinBitrate(minBitrate as! Int)
        }
      } catch {
        throw IVSBroadcastCameraViewError("Setting video config error: \(error.localizedDescription)")
      }
    } else {
      // https://docs.aws.amazon.com/ivs/latest/userguide/streaming-config.html
      assertionFailure(
        "The following properties are required for the video config, since they are interrelated: 'width', 'height', 'bitrate', 'keyframeInterval', 'targetFrameRate'. See https://docs.aws.amazon.com/ivs/latest/userguide/streaming-config.html - Resolution/Bitrate/FPS section please.")
    }
  }
  
  public func setAudioConfig(_ audioConfig: NSDictionary?) throws {
    guard let audioConfig = audioConfig else { return }
    
    do {
      if let audioBitrate = audioConfig["bitrate"] {
        try self.config.audio.setBitrate(audioBitrate as! Int)
      }
      if let audioQualityName = audioConfig["quality"] {
        let audioQuality = self.getAudioQuality(audioQualityName as! NSString)
        self.config.audio.setQuality(audioQuality)
      }
      if let channels = audioConfig["channels"] {
        try self.config.audio.setChannels(channels as! Int)
      }
      if let audioSessionStrategyName = audioConfig["audioSessionStrategy"] {
        // https://aws.github.io/amazon-ivs-broadcast-docs/1.0.0/ios/Classes/IVSBroadcastSession.html#/c:objc(cs)IVSBroadcastSession(cpy)applicationAudioSessionStrategy
        IVSBroadcastSession.applicationAudioSessionStrategy = self.getAudioSessionStrategy(audioSessionStrategyName as! NSString)
      }
    } catch {
      throw IVSBroadcastCameraViewError("Setting audio config error: \(error.localizedDescription)")
    }
  }
  
  public func setBroadcastStateChangedHandler(_ onBroadcastStateChangedHandler: RCTDirectEventBlock?) {
    self.onBroadcastStateChanged = onBroadcastStateChangedHandler
  }
  
  public func setBroadcastErrorHandler(_ onBroadcastErrorHandler: RCTDirectEventBlock?) {
    self.onBroadcastError = onBroadcastErrorHandler
  }
  
  public func setBroadcastAudioStatsHandler(_ onBroadcastAudioStatsHandler: RCTDirectEventBlock?) {
    self.onBroadcastAudioStats = onBroadcastAudioStatsHandler
  }
  
  public func setBroadcastQualityChangedHandler(_ onBroadcastQualityChangedHandler: RCTDirectEventBlock?) {
    self.onBroadcastQualityChanged = onBroadcastQualityChangedHandler
  }
  
  public func setNetworkHealthChangedHandler(_ onNetworkHealthChangedHandler: RCTDirectEventBlock?) {
    self.onNetworkHealthChanged = onNetworkHealthChangedHandler
  }
}

extension IVSBroadcastSessionService: IVSBroadcastSession.Delegate {
  func broadcastSession(_ session: IVSBroadcastSession, didChange state: IVSBroadcastSession.State) {
    self.onBroadcastStateChanged?(["stateStatus": state.rawValue])
  }
  
  func broadcastSession(_ session: IVSBroadcastSession, networkHealthChanged health: Double) {
    self.onNetworkHealthChanged?(["networkHealth": health])
  }
  
  func broadcastSession(_ session: IVSBroadcastSession, broadcastQualityChanged quality: Double) {
    self.onBroadcastQualityChanged?(["quality": quality])
  }
  
  func broadcastSession(_ session: IVSBroadcastSession, audioStatsUpdatedWithPeak peak: Double, rms: Double) {
    self.onBroadcastAudioStats?([
      "audioStats": ["peak": peak, "rms": rms]
    ])
  }
  
  func broadcastSession(_ session: IVSBroadcastSession, didEmitError error: Error) {
    if let onBroadcastError = self.onBroadcastError {
      let userInfo = (error as NSError).userInfo
      let IVSBroadcastSourceDescription = userInfo["IVSBroadcastSourceDescription"]
      let IVSBroadcastErrorIsFatalKey = userInfo["IVSBroadcastErrorIsFatalKey"]
      
      onBroadcastError([
        "exception": [
          "code": (error as NSError).code,
          "type": (error as NSError).domain,
          "detail": error.localizedDescription,
          "source": IVSBroadcastSourceDescription,
          "isFatal": IVSBroadcastErrorIsFatalKey,
        ]
      ])
    }
  }
}
