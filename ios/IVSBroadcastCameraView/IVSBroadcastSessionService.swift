import AmazonIVSBroadcast
import Foundation

typealias onErrorHandler = (_: Error) -> Void
typealias onReceiveCameraPreviewHandler = (_: IVSImagePreviewView) -> Void

enum BuiltInCameraUrns: String {
  case backUltraWideCamera = "com.apple.avfoundation.avcapturedevice.built-in_video:5"
  case backCamera = "com.apple.avfoundation.avcapturedevice.built-in_video:0"
  case frontCamera = "com.apple.avfoundation.avcapturedevice.built-in_video:1"
}

// Guide: https://docs.aws.amazon.com/ivs/latest/userguide//broadcast-ios.html
class IVSBroadcastSessionService: NSObject {
  
  private var isInitialized: Bool = false
  
  private var isInitialMuted: Bool = false
  private var initialSessionLogLevel: IVSBroadcastSession.LogLevel = .error
  private var initialCameraPosition: IVSDevicePosition = IVSDevicePosition.back
  private var isCameraPreviewMirrored: Bool = false
  private var cameraPreviewAspectMode: IVSBroadcastConfiguration.AspectMode = .none
  private var customVideoConfig: NSDictionary?
  private var customAudioConfig: NSDictionary?
  
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
  
  private func getConfigurationPreset(_ configurationPresetName: NSString) -> IVSBroadcastConfiguration {
    switch configurationPresetName {
      case "standardPortrait":
        return IVSPresets.configurations().standardPortrait()
      case "standardLandscape":
        return IVSPresets.configurations().standardLandscape()
      case "basicPortrait":
        return IVSPresets.configurations().basicPortrait()
      case "basicLandscape":
        return IVSPresets.configurations().basicLandscape()
      default:
        assertionFailure("Does not support configuration preset: \(configurationPresetName).")
        return IVSPresets.configurations().standardPortrait()
    }
  }
  
  private func getInitialDeviceDescriptorList() -> [IVSDeviceDescriptor] {
    return self.initialCameraPosition == .front ? IVSPresets.devices().frontCamera() : IVSPresets.devices().backCamera()
  }
  
  private func getNextCameraDescriptorToSwap(_ attachedCamera : IVSDevice) -> IVSDeviceDescriptor? {
    let attachedCameraPosition = attachedCamera.descriptor().position
    
    return IVSBroadcastSession
      .listAvailableDevices()
      .first { $0.type == .camera && $0.position != attachedCameraPosition}
  }
  
  private func getCameraPreview() -> IVSImagePreviewView? {
    guard let preview = try? self.broadcastSession?.previewView(with: self.cameraPreviewAspectMode) else {
      self.onError?(IVSBroadcastCameraViewError("[getCameraPreview] Can not get camera preview."))
      return nil
    }
    preview.setMirrored(self.isCameraPreviewMirrored)
    return preview
  }
  
  private func getAttachedDeviceByUrn(_ urn: String) -> IVSDevice? {
    let attachedDevices = self.broadcastSession?.listAttachedDevices()
    let wantedDeviceList = attachedDevices?.filter { $0.descriptor().urn.contains(urn) }
    
    guard let wantedDevice = wantedDeviceList?.first else {
      self.onError?(IVSBroadcastCameraViewError("[getAttachedDeviceByUrn] Can not get attached device by urn: \(urn)"))
      return nil
    }
    
    return wantedDevice
  }
  
  private func setCustomVideoConfig() throws {
    guard let videoConfig = self.customVideoConfig else { return }
    
    let width = videoConfig["width"]
    let height = videoConfig["height"]
    if (width != nil || height != nil) {
      if (width != nil && height != nil) {
        try self.config.video.setSize(CGSize(width: width as! Int, height: height as! Int))
      } else {
        self.onError?(IVSBroadcastCameraViewError("[setCustomVideoConfig] The `width` and `height` are interrelated and thus can not be used separately."))
      }
    }
    
    if let bitrate = videoConfig["bitrate"] {
      try self.config.video.setInitialBitrate(bitrate as! Int)
    }
    if let targetFrameRate = videoConfig["targetFrameRate"] {
      try self.config.video.setTargetFramerate(targetFrameRate as! Int)
    }
    if let keyframeInterval = videoConfig["keyframeInterval"] {
      try self.config.video.setKeyframeInterval(Float(keyframeInterval as! Int))
    }
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
  }
  
  private func setCustomAudioConfig() throws {
    guard let audioConfig = self.customAudioConfig else { return }
    
    if let audioBitrate = audioConfig["bitrate"] {
      try self.config.audio.setBitrate(audioBitrate as! Int)
    }
    if let channels = audioConfig["channels"] {
      try self.config.audio.setChannels(channels as! Int)
    }
    if let audioQualityName = audioConfig["quality"] {
      let audioQuality = self.getAudioQuality(audioQualityName as! NSString)
      self.config.audio.setQuality(audioQuality)
    }
    if let audioSessionStrategyName = audioConfig["audioSessionStrategy"] {
      // https://aws.github.io/amazon-ivs-broadcast-docs/1.0.0/ios/Classes/IVSBroadcastSession.html#/c:objc(cs)IVSBroadcastSession(cpy)applicationAudioSessionStrategy
      IVSBroadcastSession.applicationAudioSessionStrategy = self.getAudioSessionStrategy(audioSessionStrategyName as! NSString)
    }
  }
  
  private func swapCameraAsync(_ onReceiveCameraPreview: @escaping onReceiveCameraPreviewHandler) {
    self.checkBroadcastSessionOrThrow()
    
    self.broadcastSession?.awaitDeviceChanges { () -> Void in
      guard let attachedCamera = self.getAttachedDeviceByUrn(self.attachedCameraUrn) else {
        return
      }
      
      guard let nextCameraDescriptorToSwap = self.getNextCameraDescriptorToSwap(attachedCamera) else {
        self.onError?(IVSBroadcastCameraViewError("[swapCameraAsync] Can not get next camera to swap."))
        return
      }
      
      self.broadcastSession?.exchangeOldDevice(attachedCamera, withNewDevice: nextCameraDescriptorToSwap) { newDevice, _ in
        if let newCamera = newDevice {
          self.attachedCameraUrn = newCamera.descriptor().urn
          
          if let newCameraPreview = self.getCameraPreview() {
            onReceiveCameraPreview(newCameraPreview)
          }
        } else {
          self.onError?(IVSBroadcastCameraViewError("[swapCameraAsync] New device is empty."))
        }
      }
    }
  }
  
  private func muteAsync(_ isMuted: Bool) {
    self.broadcastSession?.awaitDeviceChanges { () -> Void in
      if let attachedMicrophone = self.getAttachedDeviceByUrn(self.attachedMicrophoneUrn) {
        let gain: Float = isMuted ? 0 : 1
        (attachedMicrophone as? IVSAudioDevice)?.setGain(gain)
      }
    }
  }
  
  private func preInitiation() throws {
    try self.setCustomVideoConfig()
    try self.setCustomAudioConfig()
  }
  
  private func postInitiation() {
    self.broadcastSession?.logLevel = self.initialSessionLogLevel
    
    if (self.isInitialMuted) {
      self.muteAsync(self.isInitialMuted)
    }
  }
  
  private func saveInitialDevicesUrn(_ initialDescriptors: [IVSDeviceDescriptor]) {
    let attachedDevices = initialDescriptors.filter { $0.type == .camera || $0.type == .microphone }
    self.attachedCameraUrn = attachedDevices.first { $0.type == .camera }?.urn ?? ""
    self.attachedMicrophoneUrn = attachedDevices.first { $0.type == .microphone }?.urn ?? ""
  }
  
  public func initiate() throws {
    if (!self.isInitialized) {
      
      try self.preInitiation()
      let initialDeviceDescriptorList = getInitialDeviceDescriptorList()
      
      self.broadcastSession = try IVSBroadcastSession(
        configuration: self.config,
        descriptors: initialDeviceDescriptorList,
        delegate: self
      )
      
      self.saveInitialDevicesUrn(initialDeviceDescriptorList)
      self.isInitialized = true
      
      self.postInitiation()
    } else {
      assertionFailure("Broadcast session has been already initialized.")
    }
  }
  
  public func deinitiate() {
    self.checkBroadcastSessionOrThrow()
    
    self.broadcastSession?.stop()
    self.broadcastSession = nil
    self.isInitialized = false
  }
  
  public func isInitiated() -> Bool {
    self.isInitialized
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
    
    guard let url = URL(string: ivsRTMPSUrl as String) else {
      self.onError?(IVSBroadcastCameraViewError("[start] Can not create a URL instance from the provided ivsRTMPSUrl: \(ivsRTMPSUrl)"))
      return
    }
    try self.broadcastSession?.start(with: url, streamKey: ivsStreamKey as String)
  }
  
  public func stop() {
    self.checkBroadcastSessionOrThrow()
    self.broadcastSession?.stop()
  }
  
  @available(*, message: "@Deprecated in favor of setCameraPosition method.")
  public func swapCamera(_ onReceiveCameraPreview: @escaping onReceiveCameraPreviewHandler) {
    self.swapCameraAsync(onReceiveCameraPreview)
  }
  
  public func getCameraPreviewAsync(_ onReceiveCameraPreview: @escaping onReceiveCameraPreviewHandler) {
    self.checkBroadcastSessionOrThrow()
    self.broadcastSession?.awaitDeviceChanges { () -> Void in
      if let cameraPreview = self.getCameraPreview() {
        onReceiveCameraPreview(cameraPreview)
      }
    }
  }
  
  public func setCameraPosition(_ cameraPosition: NSString?, _ onReceiveCameraPreview: @escaping onReceiveCameraPreviewHandler) {
    if let cameraPositionName = cameraPosition {
      if (self.isInitialized) {
        self.swapCameraAsync(onReceiveCameraPreview)
      } else {
        self.initialCameraPosition = self.getCameraPosition(cameraPositionName)
      }
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
      let sessionLogLevel = self.getLogLevel(logLevelName)
      if (self.isInitialized) {
        self.checkBroadcastSessionOrThrow()
        self.broadcastSession?.logLevel = sessionLogLevel
      } else {
        self.initialSessionLogLevel = sessionLogLevel
      }
    }
  }
  
  public func setLogLevel(_ logLevel: NSString?) {
    if let logLevelName = logLevel {
      self.config.logLevel = self.getLogLevel(logLevelName)
    }
  }
  
  public func setConfigurationPreset(_ configurationPreset: NSString?) {
    if let configurationPresetName = configurationPreset {
      self.config = self.getConfigurationPreset(configurationPresetName)
    }
  }
  
  public func setVideoConfig(_ videoConfig: NSDictionary?) throws {
    self.customVideoConfig = videoConfig
  }
  
  public func setAudioConfig(_ audioConfig: NSDictionary?) throws {
    self.customAudioConfig = audioConfig
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
          "sessionId": self.broadcastSession?.sessionId,
        ]
      ])
    }
  }
}
