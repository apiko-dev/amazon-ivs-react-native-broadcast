import UIKit
import AVFoundation

class IVSBroadcastCameraView: UIView {
  private var wasInitialSubViewAdded: Bool = false
  private let broadcastSession: IVSBroadcastSessionService = IVSBroadcastSessionService()
  
  @objc var streamKey: NSString?
  @objc var rtmpsUrl: NSString?
  @objc var isMuted: Bool = false {
    didSet {
      self.broadcastSession.setIsMuted(isMuted)
    }
  }
  @objc var isCameraPreviewMirrored: Bool = false {
    didSet {
      self.broadcastSession.setIsCameraPreviewMirrored(isCameraPreviewMirrored, self.onReceiveCameraPreviewHandler)
    }
  }
  @objc var cameraPreviewAspectMode: NSString? {
    didSet {
      self.broadcastSession.setCameraPreviewAspectMode(cameraPreviewAspectMode, self.onReceiveCameraPreviewHandler)
    }
  }
  @objc var cameraPosition: NSString? {
    didSet {
      self.broadcastSession.setCameraPosition(cameraPosition, self.onReceiveCameraPreviewHandler)
    }
  }
  @objc var sessionLogLevel: NSString? {
    didSet {
      self.broadcastSession.setSessionLogLevel(sessionLogLevel)
    }
  }
  @objc var logLevel: NSString? {
    didSet {
      self.broadcastSession.setLogLevel(logLevel)
    }
  }
  @objc var configurationPreset: NSString? {
    didSet{
      self.broadcastSession.setConfigurationPreset(configurationPreset)
    }
  }
  @objc var videoConfig: NSDictionary? {
    didSet {
      do {
        try self.broadcastSession.setVideoConfig(videoConfig)
      } catch {
        self.onErrorHandler(error)
      }
    }
  }
  @objc var audioConfig: NSDictionary? {
    didSet {
      do {
        try self.broadcastSession.setAudioConfig(audioConfig)
      } catch {
        self.onErrorHandler(error)
      }
    }
  }
  
  @objc var onIsBroadcastReady: RCTDirectEventBlock?
  @objc var onAudioSessionInterrupted: RCTDirectEventBlock?
  @objc var onAudioSessionResumed: RCTDirectEventBlock?
  @objc var onMediaServicesWereLost: RCTDirectEventBlock?
  @objc var onMediaServicesWereReset: RCTDirectEventBlock?
  @objc var onError: RCTDirectEventBlock?
  @objc var onBroadcastError: RCTDirectEventBlock? {
    didSet {
      self.broadcastSession.setBroadcastErrorHandler(onBroadcastError)
    }
  }
  @objc var onBroadcastAudioStats: RCTDirectEventBlock? {
    didSet {
      self.broadcastSession.setBroadcastAudioStatsHandler(onBroadcastAudioStats)
    }
  }
  @objc var onBroadcastStateChanged: RCTDirectEventBlock? {
    didSet {
      self.broadcastSession.setBroadcastStateChangedHandler(onBroadcastStateChanged)
    }
  }
  @objc var onBroadcastQualityChanged: RCTDirectEventBlock? {
    didSet {
      self.broadcastSession.setBroadcastQualityChangedHandler(onBroadcastQualityChanged)
    }
  }
  @objc var onNetworkHealthChanged: RCTDirectEventBlock? {
    didSet {
      self.broadcastSession.setNetworkHealthChangedHandler(onNetworkHealthChanged)
    }
  }
  
  @objc
  private func audioSessionInterrupted(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
          let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue)
    else { return }
    
    switch type {
      case .began:
        self.onAudioSessionInterrupted?([:])
      case .ended:
        self.onAudioSessionResumed?([:])
      @unknown default:
        break
    }
  }
  
  @objc
  private func mediaServicesWereLost(_ notification: Notification) {
    self.onMediaServicesWereLost?([:])
  }
  
  @objc
  private func mediaServicesWereReset(_ notification: Notification) {
    self.onMediaServicesWereReset?([:])
  }
  
  // Observing notifications sent through NSNotificationCenter (Audio Interruptions & Media Services Lost sections)
  private func subscribeToNotificationCenter() {
    let center = NotificationCenter.default
    center.addObserver(
      self,
      selector: #selector(audioSessionInterrupted(_:)),
      name: AVAudioSession.interruptionNotification,
      object: nil)
    center.addObserver(
      self,
      selector: #selector(mediaServicesWereLost(_:)),
      name: AVAudioSession.mediaServicesWereLostNotification,
      object: nil)
    center.addObserver(
      self,
      selector:  #selector(mediaServicesWereReset(_:)),
      name: AVAudioSession.mediaServicesWereResetNotification,
      object: nil)
  }
  
  private func unsubscribeNotificationCenter() {
    let center = NotificationCenter.default
    center.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
    center.removeObserver(self, name: AVAudioSession.mediaServicesWereLostNotification, object: nil)
    center.removeObserver(self, name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
  }
  
  private func onErrorHandler(_ error: Error) {
    self.onError?(["message": error.localizedDescription])
  }
  
  private func onReceiveCameraPreviewHandler(preview: UIView) {
    self.subviews.forEach { $0.removeFromSuperview() }
    preview.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(preview)
    NSLayoutConstraint.activate([
      preview.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
      preview.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
      preview.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
      preview.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
    ])
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.broadcastSession.setErrorHandler(self.onErrorHandler)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented.")
  }
  
  override func didMoveToWindow() {
    if self.window != nil {
      // Disable the Application Idle Timer. Prevents device from going to sleep while using the broadcast SDK, which would interrupt the broadcast
      UIApplication.shared.isIdleTimerDisabled = true
      if (!self.broadcastSession.isInitiated()) {
        do {
          try self.broadcastSession.initiate()
        } catch {
          self.onErrorHandler(error)
        }
        self.subscribeToNotificationCenter()
        self.broadcastSession.getCameraPreviewAsync(self.onReceiveCameraPreviewHandler)
      }
    } else {
      UIApplication.shared.isIdleTimerDisabled = false
      self.unsubscribeNotificationCenter()
      self.subviews.forEach { $0.removeFromSuperview() }
      self.broadcastSession.deinitiate()
    }
  }
  
  override func didAddSubview(_ subview: UIView) {
    if (!self.wasInitialSubViewAdded) {
      self.wasInitialSubViewAdded = true
      self.onIsBroadcastReady?(["isReady": self.broadcastSession.isReady()])
    }
  }
  
  public func start() {
    guard let rtmpsUrl = self.rtmpsUrl else {
      assertionFailure("'rtmpsUrl' prop is required.")
      return;
    }
    
    guard let streamKey = self.streamKey else {
      assertionFailure("'streamKey' prop is required.")
      return;
    }
    
    do {
      try self.broadcastSession.start(ivsRTMPSUrl: rtmpsUrl , ivsStreamKey: streamKey)
    } catch {
      self.onErrorHandler(error)
    }
  }
  
  public func stop() {
    self.broadcastSession.stop()
  }
  
  @available(*, message: "@Deprecated in favor of cameraPosition prop.")
  public func swapCamera() {
    self.broadcastSession.swapCamera(self.onReceiveCameraPreviewHandler)
  }
}
