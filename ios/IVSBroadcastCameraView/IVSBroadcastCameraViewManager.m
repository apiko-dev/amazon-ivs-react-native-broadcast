#import "React/RCTBridgeModule.h"
#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(RCTIVSBroadcastCameraView, RCTViewManager)
// Props
RCT_EXPORT_VIEW_PROPERTY(streamKey, NSString)
RCT_EXPORT_VIEW_PROPERTY(rtmpsUrl, NSString)
RCT_EXPORT_VIEW_PROPERTY(videoConfig, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(audioConfig, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(isMuted, BOOL)
RCT_EXPORT_VIEW_PROPERTY(cameraPreviewAspectMode, NSString)
RCT_EXPORT_VIEW_PROPERTY(cameraPosition, NSString)
RCT_EXPORT_VIEW_PROPERTY(isCameraPreviewMirrored, BOOL)
RCT_EXPORT_VIEW_PROPERTY(logLevel, NSString)
RCT_EXPORT_VIEW_PROPERTY(sessionLogLevel, NSString)

// Event handlers props
RCT_EXPORT_VIEW_PROPERTY(onIsBroadcastReady, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onError, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onBroadcastError, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onBroadcastAudioStats, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onBroadcastStateChanged, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onBroadcastQualityChanged, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onAudioSessionInterrupted, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onAudioSessionResumed, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onMediaServicesWereLost, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onMediaServicesWereReset, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onNetworkHealthChanged, RCTDirectEventBlock)

// Methods
RCT_EXTERN_METHOD(START:(nonnull NSNumber *)node)
RCT_EXTERN_METHOD(STOP:(nonnull NSNumber *)node)
RCT_EXTERN_METHOD(SWAP_CAMERA:(nonnull NSNumber *)node)
@end
