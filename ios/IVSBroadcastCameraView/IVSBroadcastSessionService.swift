import AmazonIVSBroadcast
import Foundation

typealias onReceiveCameraPreviewHandler = (_: IVSImagePreviewView) -> Void

enum BuiltInCameraUrns: String {
  case backUltraWideCamera = "com.apple.avfoundation.avcapturedevice.built-in_video:5"
  case backCamera = "com.apple.avfoundation.avcapturedevice.built-in_video:0"
  case frontCamera = "com.apple.avfoundation.avcapturedevice.built-in_video:1"
}

// Guide: https://docs.aws.amazon.com/ivs/latest/userguide//broadcast-ios.html
class IVSBroadcastSessionService: NSObject {
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
  
  private var onBroadcastError: RCTDirectEventBlock?
  private var onBroadcastAudioStats: RCTDirectEventBlock?
  private var onBroadcastStateChanged: RCTDirectEventBlock?
  @available(*, message: "@Deprecated in favor of onTransmissionStatisticsChanged method.")
  private var onBroadcastQualityChanged: RCTDirectEventBlock?
  @available(*, message: "@Deprecated in favor of onTransmissionStatisticsChanged method.")
  private var onNetworkHealthChanged: RCTDirectEventBlock?
  private var onTransmissionStatisticsChanged: RCTDirectEventBlock?
  
  private func getLogLevel(_ logLevelName: NSString) -> IVSBroadcastSession.LogLevel {
    switch logLevelName {
      case "debug":
        return .debug
      case "error":
        return .error
      case "info":
        return .info
      case "warning":
        return .warn
      default:
        assertionFailure("Does not support log level: \(logLevelName)")
        return .error
    }
  }
  
  private func getAspectMode(_ aspectModeName: NSString) -> IVSBroadcastConfiguration.AspectMode {
    switch aspectModeName {
      case "fit":
        return .fit
      case "fill":
        return .fill
      case "none":
        return .none
      default:
        assertionFailure("Does not support aspect mode: \(aspectModeName)")
        return .fill
    }
  }
  
  private func getCameraPosition(_ cameraPositionName: NSString) -> IVSDevicePosition {
    switch(cameraPositionName) {
      case "front":
        return .front
      case "back":
        return .back
      default:
        assertionFailure("Does not support camera position: \(cameraPositionName)")
        return .back
    }
  }
  
  private func getAudioSessionStrategy(_ audioSessionStrategyName: NSString) -> IVSBroadcastSession.AudioSessionStrategy {
    switch audioSessionStrategyName {
      case "recordOnly":
        return .recordOnly
      case "playAndRecord":
        return .playAndRecord
      case "playAndRecordDefaultToSpeaker":
        return .playAndRecordDefaultToSpeaker
      case "noAction":
        return .noAction
      default:
        assertionFailure("Does not support audio session strategy: \(audioSessionStrategyName).")
        return .playAndRecord
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
  
  private func getAutomaticBitrateProfile(_ automaticBitrateProfileName: NSString) -> IVSVideoConfiguration.AutomaticBitrateProfile {
    switch automaticBitrateProfileName {
      case "conservative":
        return .conservative
      case "fastIncrease":
        return .fastIncrease
      default:
        assertionFailure("Does not support automatic bitrate profile: \(automaticBitrateProfileName).")
        return .conservative
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
    let availableCameraDevices = IVSBroadcastSession.listAvailableDevices().filter { $0.type == .camera }
    
    return availableCameraDevices
      .first {
        let isOppositePosition = $0.position != attachedCameraPosition
        return availableCameraDevices.count > 2 && attachedCameraPosition == .front ? isOppositePosition && $0.isDefault : isOppositePosition
      }
  }
  
  private func getCameraPreview() -> IVSImagePreviewView? {
    let preview = try? self.broadcastSession?.previewView(with: self.cameraPreviewAspectMode)
    preview?.setMirrored(self.isCameraPreviewMirrored)
    return preview
  }
  
  private func getAttachedDeviceByUrn(_ urn: String) -> IVSDevice? {
    let attachedDevices = self.broadcastSession?.listAttachedDevices()
    let wantedDeviceList = attachedDevices?.filter { $0.descriptor().urn.contains(urn) }
    return wantedDeviceList?.first
  }
  
  private func setCustomVideoConfig() throws {
    guard let videoConfig = self.customVideoConfig else { return }
    
    let width = videoConfig["width"]
    let height = videoConfig["height"]
    if (width != nil || height != nil) {
      if (width != nil && height != nil) {
        try self.config.video.setSize(CGSize(width: width as! Int, height: height as! Int))
      } else {
        throw IVSBroadcastCameraViewError("[setCustomVideoConfig] The `width` and `height` are interrelated and thus can not be used separately.")
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
    if let autoBitrateProfileName = videoConfig["autoBitrateProfile"] {
      let autoBitrateProfile = self.getAutomaticBitrateProfile(autoBitrateProfileName as! NSString)
      self.config.video.autoBitrateProfile = autoBitrateProfile
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
      IVSBroadcastSession.applicationAudioSessionStrategy = self.getAudioSessionStrategy(audioSessionStrategyName as! NSString)
    }
  }
  
  private func swapCameraAsync(_ onReceiveCameraPreview: @escaping onReceiveCameraPreviewHandler) {
    self.broadcastSession?.awaitDeviceChanges { () -> Void in
      guard let attachedCamera = self.getAttachedDeviceByUrn(self.attachedCameraUrn) else {
        return
      }
      
      guard let nextCameraDescriptorToSwap = self.getNextCameraDescriptorToSwap(attachedCamera) else {
        return
      }
      
      self.broadcastSession?.exchangeOldDevice(attachedCamera, withNewDevice: nextCameraDescriptorToSwap) { newDevice, _ in
        if let newCamera = newDevice {
          self.attachedCameraUrn = newCamera.descriptor().urn
          
          if let newCameraPreview = self.getCameraPreview() {
            onReceiveCameraPreview(newCameraPreview)
          }
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
  
  private func saveInitialDevicesUrn(_ initialDescriptors: [IVSDeviceDescriptor]) {
    let attachedDevices = initialDescriptors.filter { $0.type == .camera || $0.type == .microphone }
    self.attachedCameraUrn = attachedDevices.first { $0.type == .camera }?.urn ?? ""
    self.attachedMicrophoneUrn = attachedDevices.first { $0.type == .microphone }?.urn ?? ""
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
  
  public func initiate() throws {
    if (!self.isInitialized()) {
      try self.preInitiation()
      let initialDeviceDescriptorList = getInitialDeviceDescriptorList()
      
      self.broadcastSession = try IVSBroadcastSession(
        configuration: self.config,
        descriptors: initialDeviceDescriptorList,
        delegate: self
      )
      
      self.saveInitialDevicesUrn(initialDeviceDescriptorList)
      self.postInitiation()
    } else {
      assertionFailure("Broadcast session has been already initialized.")
    }
  }
  
  public func deinitiate() {
    self.broadcastSession?.stop()
    self.broadcastSession = nil
  }
  
  public func isInitialized() -> Bool {
    return self.broadcastSession != nil
  }
  
  public func isReady() -> Bool {
    guard let isReady = self.broadcastSession?.isReady else {
      return false
    }
    return isReady
  }
  
  public func start(ivsRTMPSUrl: NSString, ivsStreamKey: NSString) throws {
    guard let url = URL(string: ivsRTMPSUrl as String) else {
      throw IVSBroadcastCameraViewError("[start] Can not create a URL instance for: \(ivsRTMPSUrl)")
    }
    try self.broadcastSession?.start(with: url, streamKey: ivsStreamKey as String)
  }
  
  public func stop() {
    self.broadcastSession?.stop()
  }
  
  @available(*, message: "@Deprecated in favor of setCameraPosition method.")
  public func swapCamera(_ onReceiveCameraPreview: @escaping onReceiveCameraPreviewHandler) {
    self.swapCameraAsync(onReceiveCameraPreview)
  }
  
  public func getCameraPreviewAsync(_ onReceiveCameraPreview: @escaping onReceiveCameraPreviewHandler) {
    self.broadcastSession?.awaitDeviceChanges { () -> Void in
      if let cameraPreview = self.getCameraPreview() {
        onReceiveCameraPreview(cameraPreview)
      }
    }
  }
  
  public func setCameraPosition(_ cameraPosition: NSString?, _ onReceiveCameraPreview: @escaping onReceiveCameraPreviewHandler) {
    if let cameraPositionName = cameraPosition {
      if (self.isInitialized()) {
        self.swapCameraAsync(onReceiveCameraPreview)
      } else {
        self.initialCameraPosition = self.getCameraPosition(cameraPositionName)
      }
    }
  }
  
  public func setCameraPreviewAspectMode(_ aspectMode: NSString?, _ onReceiveCameraPreview: @escaping onReceiveCameraPreviewHandler) {
    if let aspectModeName = aspectMode {
      self.cameraPreviewAspectMode = self.getAspectMode(aspectModeName)
      
      if (self.isInitialized()) {
        self.getCameraPreviewAsync(onReceiveCameraPreview)
      }
    }
  }
  
  public func setIsCameraPreviewMirrored(_ isMirrored: Bool, _ onReceiveCameraPreview: @escaping onReceiveCameraPreviewHandler) {
    self.isCameraPreviewMirrored = isMirrored
    
    if (self.isInitialized()) {
      self.getCameraPreviewAsync(onReceiveCameraPreview)
    }
  }
  
  public func setIsMuted(_ isMuted: Bool) {
    if (self.isInitialized()) {
      self.muteAsync(isMuted)
    } else {
      self.isInitialMuted = isMuted
    }
  }
  
  public func setSessionLogLevel(_ logLevel: NSString?) {
    if let logLevelName = logLevel {
      let sessionLogLevel = self.getLogLevel(logLevelName)
      
      if (self.isInitialized()) {
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
  
  public func setVideoConfig(_ videoConfig: NSDictionary?) {
    self.customVideoConfig = videoConfig
  }
  
  public func setAudioConfig(_ audioConfig: NSDictionary?) {
    self.customAudioConfig = audioConfig
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
  
  @available(*, message: "@Deprecated in favor of setTransmissionStatisticsChangedHandler method.")
  public func setBroadcastQualityChangedHandler(_ onBroadcastQualityChangedHandler: RCTDirectEventBlock?) {
    self.onBroadcastQualityChanged = onBroadcastQualityChangedHandler
  }
  
  @available(*, message: "@Deprecated in favor of setTransmissionStatisticsChangedHandler method.")
  public func setNetworkHealthChangedHandler(_ onNetworkHealthChangedHandler: RCTDirectEventBlock?) {
    self.onNetworkHealthChanged = onNetworkHealthChangedHandler
  }
  
  public func setTransmissionStatisticsChangedHandler(_ onTransmissionStatisticsChangedHandler: RCTDirectEventBlock?) {
    self.onTransmissionStatisticsChanged = onTransmissionStatisticsChangedHandler
  }
}

extension IVSBroadcastSessionService: IVSBroadcastSession.Delegate {
  func broadcastSession(_ session: IVSBroadcastSession, transmissionStatisticsChanged statistics: IVSTransmissionStatistics) {
    self.onTransmissionStatisticsChanged?([
      "statistics": [
        "rtt": statistics.rtt,
        "measuredBitrate": statistics.measuredBitrate,
        "recommendedBitrate": statistics.recommendedBitrate,
        "networkHealth": statistics.networkHealth.rawValue,
        "broadcastQuality": statistics.broadcastQuality.rawValue,
      ]
    ])
    
  }
  
  func broadcastSession(_ session: IVSBroadcastSession, didChange state: IVSBroadcastSession.State) {
    var eventPayload = ["stateStatus": state.rawValue] as [AnyHashable : Any]
    
    if (state == .connected) {
      eventPayload["metadata"] = ["sessionId": session.sessionId]
    }
    
    self.onBroadcastStateChanged?(eventPayload)
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
          "sessionId": session.sessionId,
        ]
      ])
    }
  }
}
