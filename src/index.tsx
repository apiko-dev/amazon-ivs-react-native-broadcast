import React, {
  useRef,
  forwardRef,
  useCallback,
  useImperativeHandle,
} from 'react';
import {
  Platform,
  UIManager,
  findNodeHandle,
  requireNativeComponent,
} from 'react-native';
import PropTypes from 'prop-types';

const UNKNOWN = 'unknown';

const RNIVSBroadcastCameraView = requireNativeComponent(
  'RNIVSBroadcastCameraView'
);

const COMMANDS_MAP = {
  Start: 'START',
  Stop: 'STOP',
  SwapCamera: 'SWAP_CAMERA',
};

const EVENT_PAYLOAD_KEY_NAMES_MAP = {
  Message: 'message',
  IsReady: 'isReady',
  Quality: 'quality',
  Exception: 'exception',
  AudioStats: 'audioStats',
  StateStatus: 'stateStatus',
  NetworkHealth: 'networkHealth',
};

const NATIVE_SIDE_COMMANDS = UIManager.getViewManagerConfig(
  'RNIVSBroadcastCameraView'
).Commands;

const STATE_STATUSES_MAP = {
  Connected: 'CONNECTED',
  Connecting: 'CONNECTING',
  Disconnected: 'DISCONNECTED',
  Error: 'ERROR',
  Invalid: 'INVALID',
};

const {
  Exception,
  IsReady,
  AudioStats,
  StateStatus,
  Quality,
  Message,
  NetworkHealth,
} = EVENT_PAYLOAD_KEY_NAMES_MAP;

const IVSBroadcastCameraView = (props, parentRef) => {
  const {
    onError,
    onBroadcastError,
    onIsBroadcastReady,
    onBroadcastAudioStats,
    onNetworkHealthChanged,
    onBroadcastStateChanged,
    onBroadcastQualityChanged,
    onAudioSessionInterrupted,
    onAudioSessionResumed,
    onMediaServicesWereLost,
    onMediaServicesWereReset,
    ...restProps
  } = props;

  const ivsBroadcastCameraViewRef = useRef();

  useImperativeHandle(
    parentRef,
    () => {
      const reactTag = findNodeHandle(ivsBroadcastCameraViewRef.current);

      return {
        start: () =>
          UIManager.dispatchViewManagerCommand(
            reactTag,
            Platform.select({
              ios: NATIVE_SIDE_COMMANDS[COMMANDS_MAP.Start],
              android: COMMANDS_MAP.Start,
            }),
            []
          ),
        stop: () =>
          UIManager.dispatchViewManagerCommand(
            reactTag,
            Platform.select({
              ios: NATIVE_SIDE_COMMANDS[COMMANDS_MAP.Stop],
              android: COMMANDS_MAP.Stop,
            }),
            []
          ),
        swapCamera: () =>
          UIManager.dispatchViewManagerCommand(
            reactTag,
            Platform.select({
              ios: NATIVE_SIDE_COMMANDS[COMMANDS_MAP.SwapCamera],
              android: COMMANDS_MAP.SwapCamera,
            }),
            []
          ),
      };
    },
    []
  );

  const onErrorHandler = useCallback(
    ({ nativeEvent }) => {
      if (typeof onError === 'function') {
        onError(nativeEvent[Message]);
      }
    },
    [onError]
  );

  const onBroadcastErrorHandler = useCallback(
    ({ nativeEvent }) => {
      const exception = nativeEvent[Exception];
      const { code, type, detail, source, isFatal } = exception;

      if (typeof onBroadcastError === 'function') {
        onBroadcastError({
          code: String(code) ?? UNKNOWN,
          type: type ?? UNKNOWN,
          source: source ?? UNKNOWN,
          detail: detail ?? '',
          isFatal: !!isFatal,
        });
      }
    },
    [onBroadcastError]
  );

  const onIsBroadcastReadyHandler = useCallback(
    ({ nativeEvent }) => {
      if (typeof onIsBroadcastReady === 'function') {
        onIsBroadcastReady(nativeEvent[IsReady]);
      }
    },
    [onIsBroadcastReady]
  );

  const onBroadcastAudioStatsHandler = useCallback(
    ({ nativeEvent }) => {
      if (typeof onBroadcastAudioStats === 'function') {
        onBroadcastAudioStats(nativeEvent[AudioStats]);
      }
    },
    [onBroadcastAudioStats]
  );

  const onBroadcastStateChangedHandler = useCallback(
    ({ nativeEvent }) => {
      const stateStatus = nativeEvent[StateStatus];

      if (typeof onBroadcastStateChanged === 'function') {
        if (Platform.OS === 'android') {
          onBroadcastStateChanged(stateStatus);
        } else {
          switch (stateStatus) {
            case 0: {
              onBroadcastStateChanged(STATE_STATUSES_MAP.Invalid);
              break;
            }
            case 1: {
              onBroadcastStateChanged(STATE_STATUSES_MAP.Disconnected);
              break;
            }
            case 2: {
              onBroadcastStateChanged(STATE_STATUSES_MAP.Connecting);
              break;
            }
            case 3: {
              onBroadcastStateChanged(STATE_STATUSES_MAP.Connected);
              break;
            }
            case 4: {
              onBroadcastStateChanged(STATE_STATUSES_MAP.Error);
              break;
            }
            default: {
              break;
            }
          }
        }
      }
    },
    [onBroadcastStateChanged]
  );

  const onNetworkHealthChangedHandler = useCallback(
    ({ nativeEvent }) => {
      if (typeof onNetworkHealthChanged === 'function') {
        onNetworkHealthChanged(nativeEvent[NetworkHealth]);
      }
    },
    [onNetworkHealthChanged]
  );

  const onBroadcastQualityChangedHandler = useCallback(
    ({ nativeEvent }) => {
      if (typeof onBroadcastQualityChanged === 'function') {
        onBroadcastQualityChanged(nativeEvent[Quality]);
      }
    },
    [onBroadcastQualityChanged]
  );

  const onAudioSessionInterruptedHandler = useCallback(() => {
    if (typeof onAudioSessionInterrupted === 'function') {
      onAudioSessionInterrupted();
    }
  }, [onAudioSessionInterrupted]);

  const onAudioSessionResumedHandler = useCallback(() => {
    if (typeof onAudioSessionResumed === 'function') {
      onAudioSessionResumed();
    }
  }, [onAudioSessionResumed]);

  const onMediaServicesWereLostHandler = useCallback(() => {
    if (typeof onMediaServicesWereLost === 'function') {
      onMediaServicesWereLost();
    }
  }, [onMediaServicesWereLost]);

  const onMediaServicesWereResetHandler = useCallback(() => {
    if (typeof onMediaServicesWereReset === 'function') {
      onMediaServicesWereReset();
    }
  }, [onMediaServicesWereReset]);

  return (
    <RNIVSBroadcastCameraView
      {...restProps}
      ref={ivsBroadcastCameraViewRef}
      onError={onErrorHandler}
      onBroadcastError={onBroadcastErrorHandler}
      onIsBroadcastReady={onIsBroadcastReadyHandler}
      onBroadcastAudioStats={onBroadcastAudioStatsHandler}
      onBroadcastStateChanged={onBroadcastStateChangedHandler}
      onBroadcastQualityChanged={onBroadcastQualityChangedHandler}
      onNetworkHealthChanged={onNetworkHealthChangedHandler}
      onAudioSessionInterrupted={onAudioSessionInterruptedHandler}
      onAudioSessionResumed={onAudioSessionResumedHandler}
      onMediaServicesWereLost={onMediaServicesWereLostHandler}
      onMediaServicesWereReset={onMediaServicesWereResetHandler}
    />
  );
};

const BroadcastCameraView = forwardRef(IVSBroadcastCameraView);

BroadcastCameraView.defaultProps = {
  isCameraPreviewMirrored: false,
  cameraPosition: 'back',
  cameraPreviewAspectMode: 'none',
  logLevel: 'error',
  sessionLogLevel: 'error',
};

const LOG_LEVEL_LIST = ['debug', 'error', 'info', 'warning'];

BroadcastCameraView.propTypes = {
  streamKey: PropTypes.string.isRequired, // The broadcaster’s stream key that has been provided by IVS
  rtmpsUrl: PropTypes.string.isRequired, // The RTMPS endpoint provided by IVS
  isCameraPreviewMirrored: PropTypes.bool, // Flips the camera preview horizontally
  cameraPreviewAspectMode: PropTypes.oneOf(['fit', 'fill', 'none']), // Determines how view's aspect ratio will be maintained
  cameraPosition: PropTypes.oneOf(['back', 'front']),
  // In order to catch logs at a more granular level than Error during the initialization process,
  // use 'logLevel' instead of the 'sessionLogLevel' property
  logLevel: PropTypes.oneOf(LOG_LEVEL_LIST),
  sessionLogLevel: PropTypes.oneOf(LOG_LEVEL_LIST), // Logging level for the broadcast session
  videoConfig: PropTypes.shape({
    width: PropTypes.number.isRequired, // The smallest size is 160, and the largest is either 1080 or 1920
    height: PropTypes.number.isRequired, // The smallest size is 160, and the largest is either 1080 or 1920
    bitrate: PropTypes.number.isRequired, // This must be between 100_000(100k) and 8_500_000(8500k)
    targetFrameRate: PropTypes.number.isRequired, // This must be between 10 and 60
    keyframeInterval: PropTypes.number.isRequired, // This must be between 1 and 10
    isBFrames: PropTypes.bool, // Whether the output video stream uses B (Bidirectional predicted picture) frames.
    isAutoBitrate: PropTypes.bool, // Whether the output video stream will automatically adjust the bitrate based on network conditions.
    maxBitrate: PropTypes.number, // This must be between 100_000(100k) and 8_500_000(8500k)
    minBitrate: PropTypes.number, // This must be between 100_000(100k) and 8_500_000(8500k)
  }),
  audioConfig: PropTypes.shape({
    bitrate: PropTypes.number, // This must be greater than 64_000(64k) and less than 160_000(160k)
    // A value representing how the broadcast session will interact with AVAudioSession
    audioSessionStrategy: PropTypes.oneOf([
      'recordOnly',
      'playAndRecord',
      'noAction',
    ]), //! NOTE: iOS only
    channels: PropTypes.oneOf([1, 2]), // The number of channels for the output audio stream
  }),
  onBroadcastError: PropTypes.func, // Indicates that an error occurred. Errors may or may not be fatal
  onError: PropTypes.func, // Indicates that module' error occurred.
  onIsBroadcastReady: PropTypes.func, //! Whether or not the session is ready for use. NOTE: Handler fires once - after adding camera preview to the view hierarchy
  onBroadcastAudioStats: PropTypes.func, //! Periodically called with audio peak and rms in dBFS. Range is -100 (silent) to 0. NOTE: Currently is disabled internally for both platforms
  onBroadcastStateChanged: PropTypes.func, // Indicates that the broadcast state changed
  onAudioSessionInterrupted: PropTypes.func, //! Indicates that audio session has been interrupted. NOTE: iOS only
  onAudioSessionResumed: PropTypes.func, //! Indicates that audio session has been resumed (after interrupted). NOTE: iOS only
  onMediaServicesWereLost: PropTypes.func, //! Indicates that the media server services are terminated. NOTE: iOS only
  onMediaServicesWereReset: PropTypes.func, //! Indicates that the media server services are reset. NOTE: iOS only
  onBroadcastQualityChanged: PropTypes.func, // Represents the quality of the stream based on bitrate minimum and maximum provided on session configuration
  onNetworkHealthChanged: PropTypes.func, // Provides updates when the instantaneous quality of the network changes. It can be used to provide feedback about when the broadcast might have temporary disruptions
};

export default BroadcastCameraView;
