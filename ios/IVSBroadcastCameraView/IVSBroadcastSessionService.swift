import AmazonIVSBroadcast
import Foundation

typealias onErrorHandler = (_: Error) -> Void
typealias onReceiveCameraPreviewHandler = (_: IVSImagePreviewView) -> Void

enum BuiltInCameraDeviceUrns: String {
  case backUltraWideCamera = "com.apple.avfoundation.avcapturedevice.built-in_video:5"
  case backCamera = "com.apple.avfoundation.avcapturedevice.built-in_video:0"
  case frontCamera = "com.apple.avfoundation.avcapturedevice.built-in_video:1"
}

// Guide: https://docs.aws.amazon.com/ivs/latest/userguide//broadcast-ios.html
class IVSBroadcastSessionService: NSObject {
  
  private var isInitialized: Bool = false
  
  private var isInitialMuted: Bool = false
  private var initialCameraPosition: IVSDevicePosition = IVSDevicePosition.back
  
  private var isCameraPreviewMirrored: Bool = false
  private var cameraPreviewAspectMode: IVSBroadcastConfiguration.AspectMode = .none
  private var sessionLogLevel: IVSBroadcastSession.LogLevel = .error
  
  private var attachedCameraUrn: String = ""
  private var attachedMicrophoneUrn: String = ""
  
  private var broadcastSession: IVSBroadcastSession?
  private var config = IVSBroadcastConfiguration()
  
  private var onError: onErrorHandler?
  private var onBroadcastError: RCTDirectEventBlock?
  private var onBroadcastAudioStats: RCTDirectEventBlock?
  private var onBroadcastStateChanged: RCTDirectEventBlock?
  private var onBroadcastQualityChanged: RCTDirectEventBlock?
  private var onNetworkHealthChanged: RCTDirectEventBlock?
  
  private func checkBroadcastSessionOrThrow() {
    if (self.broadcastSession == nil || !self.isInitialized) {
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
  
  private func getInitialDeviceDescriptorList() -> [IVSDeviceDescriptor] {
    switch(self.initialCameraPosition) {
      case .front:
        return IVSPresets.devices().frontCamera()
      default:
        return IVSPresets.devices().backCamera()
    }
  }
  
  private func saveInitialDevicesUrn(_ initialDescriptors: [IVSDeviceDescriptor]) {
    if let initialCameraDescriptor = initialDescriptors.filter({ $0.type == .camera }).first {
      self.attachedCameraUrn = initialCameraDescriptor.urn
    }
    
    if let initialMicrophoneDescriptor = initialDescriptors.filter({ $0.type == .microphone }).first {
      self.attachedMicrophoneUrn = initialMicrophoneDescriptor.urn
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
  
  private func getNextCameraDescriptorToSwap(_ attachedCamera : IVSDevice) -> IVSDeviceDescriptor? {
    let attachedCameraPosition = attachedCamera.descriptor().position
    
    let foundCamera = IVSBroadcastSession
      .listAvailableDevices()
      .first { $0.type == .camera && $0.urn.contains(attachedCameraPosition == IVSDevicePosition.back
                                                     ? self.geDefaultFrontCameraUrn()
                                                     : self.geDefaultBackCameraUrn())}
    
    guard let nextCamera = foundCamera else {
      // NOTE: Defensive code
      return IVSBroadcastSession
        .listAvailableDevices()
        .first { $0.type == .camera && $0.position != attachedCameraPosition }
    }
    
    return nextCamera
  }
  
  private func getCameraPreview(_ aspectMode: IVSBroadcastConfiguration.AspectMode) -> IVSImagePreviewView? {
    return try? self.broadcastSession?.previewView(with: aspectMode)
  }
  
  private func getAttachedDeviceByUrn(_ urn: String) -> IVSDevice? {
    let attachedDevices = self.broadcastSession?.listAttachedDevices()
    let wantedDeviceList = attachedDevices?.filter { $0.descriptor().urn.contains(urn) }
    
    return wantedDeviceList?.first
  }
  
  private func muteAsync(_ isMuted: Bool) {
    self.broadcastSession?.awaitDeviceChanges { () -> Void in
     guard let attachedMicrophone = self.getAttachedDeviceByUrn(self.attachedMicrophoneUrn) else {
        self.onError?(IVSBroadcastCameraViewError("[muteAsync] Can not get attached microphone. \(self.attachedMicrophoneUrn)"))
        return
      }
      
      let gain: Float = isMuted ? 0 : 1
      (attachedMicrophone as? IVSAudioDevice)?.setGain(gain)
    }
  }
  
  private func swapCameraAsync(_ aspectMode: IVSBroadcastConfiguration.AspectMode, _ isMirrored: Bool, _ onReceiveCameraPreview: @escaping onReceiveCameraPreviewHandler) {
    self.broadcastSession?.awaitDeviceChanges { () -> Void in
      guard let attachedCamera = self.getAttachedDeviceByUrn(self.attachedCameraUrn) else {
        self.onError?(IVSBroadcastCameraViewError("[swapCameraAsync] Can not get attached camera. \(self.attachedCameraUrn)"))
        return
      }
      
      guard let nextCameraDescriptorToSwap = self.getNextCameraDescriptorToSwap(attachedCamera) else {
        self.onError?(IVSBroadcastCameraViewError("[swapCameraAsync] Can not get next camera to swap."))
        return
      }
      
      self.broadcastSession?.exchangeOldDevice(attachedCamera, withNewDevice: nextCameraDescriptorToSwap) { newDevice, _ in
        if let newCamera = newDevice {
          guard let newCameraPreview = try? (newCamera as! IVSImageDevice).previewView(with: aspectMode) else {
            self.onError?(IVSBroadcastCameraViewError("[swapCameraAsync] Can not get camera preview."))
            return
          }
          
          newCameraPreview.setMirrored(isMirrored)
          onReceiveCameraPreview(newCameraPreview)
          self.attachedCameraUrn = newCamera.descriptor().urn
        } else {
          self.onError?(IVSBroadcastCameraViewError("[swapCameraAsync] New device is empty."))
        }
      }
    }
  }
  
  private func postInitiation() {
    self.broadcastSession?.logLevel = self.sessionLogLevel
    
    if (self.isInitialMuted) {
      self.muteAsync(self.isInitialMuted)
    }
  }
  
  public func initiate() throws {
    if (!self.isInitialized) {
      
      let initialDeviceDescriptorList = getInitialDeviceDescriptorList()
      
      do {
        self.broadcastSession = try IVSBroadcastSession(
          configuration: self.config,
          descriptors: initialDeviceDescriptorList,
          delegate: self
        )
        self.isInitialized = true
      } catch {
        throw IVSBroadcastCameraViewError("[initiate] Can not initiate IVSBroadcastSessionService. \(error.localizedDescription)")
      }
      
      self.saveInitialDevicesUrn(initialDeviceDescriptorList)
      self.postInitiation()
    } else {
      assertionFailure("Broadcast session has been already initialized.")
    }
  }
  
  public func isInitiated() -> Bool {
    self.isInitialized
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
  
  public func isReady() -> Bool {
    self.checkBroadcastSessionOrThrow()
    
    guard let isReady = self.broadcastSession?.isReady else {
      return false
    }
    return isReady
  }
  
  public func start(ivsRTMPSUrl: NSString, ivsStreamKey: NSString) throws {
    self.checkBroadcastSessionOrThrow()
    
    do {
      guard let url = URL(string: ivsRTMPSUrl as String) else { throw IVSBroadcastCameraViewError("[start] Can not create a URL instance from the provided ivsRTMPSUrl: \(ivsRTMPSUrl)") }
      try self.broadcastSession?.start(with: url, streamKey: ivsStreamKey as String)
    } catch {
      throw IVSBroadcastCameraViewError("[start] Can not start the configured broadcast session. \(error.localizedDescription)")
    }
  }
  
  public func stop() {
    self.checkBroadcastSessionOrThrow()
    self.broadcastSession?.stop()
  }
  
  @available(*, message: "Deprecated in favor of setCameraPosition method.")
  public func swapCamera(_ onReceiveCameraPreview: @escaping onReceiveCameraPreviewHandler) {
    self.checkBroadcastSessionOrThrow()
    self.swapCameraAsync(self.cameraPreviewAspectMode, self.isCameraPreviewMirrored, onReceiveCameraPreview)
  }
  
  // Receive camera preview asynchronously to ensure that all devices have been attached
  public func getCameraPreviewAsync(_ onReceiveCameraPreview: @escaping onReceiveCameraPreviewHandler) {
    self.checkBroadcastSessionOrThrow()
    
    self.broadcastSession?.awaitDeviceChanges { () -> Void in
      guard let cameraPreview = self.getCameraPreview(self.cameraPreviewAspectMode) else {
        self.onError?(IVSBroadcastCameraViewError("[getCameraPreviewAsync] Can not get camera preview."))
        return
      }
      cameraPreview.setMirrored(self.isCameraPreviewMirrored)
      onReceiveCameraPreview(cameraPreview)
    }
  }
  
  public func setCameraPreviewAspectMode(_ aspectMode: NSString?, _ onReceiveCameraPreview: @escaping onReceiveCameraPreviewHandler) {
    if let aspectModeName = aspectMode {
      self.cameraPreviewAspectMode = self.getAspectMode(aspectModeName)
      if (self.isInitialized) {
        self.getCameraPreviewAsync(onReceiveCameraPreview)
      }
    }
  }
  
  public func setCameraPosition(_ cameraPosition: NSString?, _ onReceiveCameraPreview: @escaping onReceiveCameraPreviewHandler) {
    if let cameraPositionName = cameraPosition {
      if (self.isInitialized) {
        self.checkBroadcastSessionOrThrow()
        self.swapCameraAsync(self.cameraPreviewAspectMode, self.isCameraPreviewMirrored, onReceiveCameraPreview)
      } else {
        self.initialCameraPosition = self.getCameraPosition(cameraPositionName)
      }
    }
  }
  
  public func setIsCameraPreviewMirrored(_ isMirrored: Bool, _ onReceiveCameraPreview: @escaping onReceiveCameraPreviewHandler) {
    self.isCameraPreviewMirrored = isMirrored
    if (self.isInitialized) {
      self.getCameraPreviewAsync(onReceiveCameraPreview)
    }
  }
  
  public func setIsMuted(_ isMuted: Bool) {
    if (self.isInitialized) {
      self.checkBroadcastSessionOrThrow()
      self.muteAsync(isMuted)
    } else {
      self.isInitialMuted = isMuted
    }
  }
  
  public func setSessionLogLevel(_ logLevel: NSString?) {
    if let logLevelName = logLevel {
      self.sessionLogLevel = self.getLogLevel(logLevelName)
    }
  }
  
  public func setLogLevel(_ logLevel: NSString?) {
    if let logLevelName = logLevel {
      self.config.logLevel = self.getLogLevel(logLevelName)
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
        throw IVSBroadcastCameraViewError("[setVideoConfig] Setting video config error: \(error.localizedDescription)")
      }
    } else {
      // https://docs.aws.amazon.com/ivs/latest/userguide/streaming-config.html
      throw IVSBroadcastCameraViewError("[setVideoConfig] 'width', 'height', 'bitrate', 'keyframeInterval', 'targetFrameRate' are required since they are interrelated")
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
      throw IVSBroadcastCameraViewError("[setAudioConfig] Setting audio config error: \(error.localizedDescription)")
    }
  }
  
  public func setBroadcastStateChangedHandler(_ onBroadcastStateChangedHandler: RCTDirectEventBlock?) {
    self.onBroadcastStateChanged = onBroadcastStateChangedHandler
  }
  
  public func setErrorHandler(_ onErrorHandler: @escaping onErrorHandler) {
    self.onError = onErrorHandler
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
