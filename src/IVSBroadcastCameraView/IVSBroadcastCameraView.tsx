import React, {
  useRef,
  forwardRef,
  useImperativeHandle,
  PropsWithChildren,
} from 'react';
import {
  Platform,
  UIManager,
  findNodeHandle,
  requireNativeComponent,
} from 'react-native';

import {
  Command,
  StateStatus,
  EventPayloadKey,
  StateStatusUnion,
  ICameraView,
  ICameraViewProps,
  ICameraNativeViewProps,
} from './IVSBroadcastCameraView.types';

const UNKNOWN = 'unknown';
const NATIVE_VIEW_NAME = 'RCTIVSBroadcastCameraView';

const RCTIVSBroadcastCameraView =
  requireNativeComponent<ICameraNativeViewProps>(NATIVE_VIEW_NAME);

const NATIVE_SIDE_COMMANDS =
  UIManager.getViewManagerConfig(NATIVE_VIEW_NAME).Commands;

const getCommandIdByPlatform = (command: Command) => {
  switch (Platform.OS) {
    case 'android': {
      return command;
    }
    case 'ios': {
      return NATIVE_SIDE_COMMANDS[command];
    }
    default: {
      return '';
    }
  }
};

const {
  BroadcastErrorHandler,
  IsBroadcastReadyHandler,
  BroadcastAudioStatsHandler,
  BroadcastStateChangedHandler,
  BroadcastQualityChangedHandler,
  ErrorHandler,
  NetworkHealthChangedHandler: NetworkHealth,
} = EventPayloadKey;

const IVSBroadcastCameraView = forwardRef<
  ICameraView,
  PropsWithChildren<ICameraViewProps>
>((props, parentRef) => {
  const {
    onError,
    onBroadcastError,
    onIsBroadcastReady,
    onBroadcastAudioStats,
    onBroadcastStateChanged,
    onBroadcastQualityChanged,
    onNetworkHealthChanged,
    onAudioSessionInterrupted,
    onAudioSessionResumed,
    onMediaServicesWereLost,
    onMediaServicesWereReset,
    isCameraPreviewMirrored = false,
    cameraPosition = 'back',
    cameraPreviewAspectMode = 'none',
    logLevel = 'error',
    sessionLogLevel = 'error',
    ...restProps
  } = props;

  const nativeViewRef = useRef(null);

  useImperativeHandle<ICameraView, ICameraView>(
    parentRef,
    () => {
      const reactTag = findNodeHandle(nativeViewRef.current);

      const dispatchViewManagerCommand = (command: Command) =>
        UIManager.dispatchViewManagerCommand(
          reactTag,
          getCommandIdByPlatform(command),
          []
        );

      return {
        start: () => dispatchViewManagerCommand(Command.Start),
        stop: () => dispatchViewManagerCommand(Command.Stop),
        swapCamera: () => dispatchViewManagerCommand(Command.SwapCamera),
      };
    },
    []
  );

  const onErrorHandler: ICameraNativeViewProps['onError'] = ({ nativeEvent }) =>
    onError?.(nativeEvent[ErrorHandler]);

  const onBroadcastErrorHandler: ICameraNativeViewProps['onBroadcastError'] = ({
    nativeEvent,
  }) => {
    const exception = nativeEvent[BroadcastErrorHandler];
    const { code, type, detail, source, isFatal } = exception;

    onBroadcastError?.({
      code: String(code) ?? UNKNOWN,
      type: type ?? UNKNOWN,
      source: source ?? UNKNOWN,
      detail: detail ?? '',
      isFatal: !!isFatal,
    });
  };

  const onIsBroadcastReadyHandler: ICameraNativeViewProps['onIsBroadcastReady'] =
    ({ nativeEvent }) =>
      onIsBroadcastReady?.(nativeEvent[IsBroadcastReadyHandler]);

  const onBroadcastAudioStatsHandler: ICameraNativeViewProps['onBroadcastAudioStats'] =
    ({ nativeEvent }) =>
      onBroadcastAudioStats?.(nativeEvent[BroadcastAudioStatsHandler]);

  const onBroadcastStateChangedHandler: ICameraNativeViewProps['onBroadcastStateChanged'] =
    ({ nativeEvent }) => {
      const incomingStateStatus = nativeEvent[BroadcastStateChangedHandler];
      const outcomingStateStatus = (
        typeof incomingStateStatus === 'number'
          ? StateStatus[incomingStateStatus]
          : incomingStateStatus
      ) as StateStatusUnion;
      onBroadcastStateChanged?.(outcomingStateStatus);
    };

  const onNetworkHealthChangedHandler: ICameraNativeViewProps['onNetworkHealthChanged'] =
    ({ nativeEvent }) => onNetworkHealthChanged?.(nativeEvent[NetworkHealth]);

  const onBroadcastQualityChangedHandler: ICameraNativeViewProps['onBroadcastQualityChanged'] =
    ({ nativeEvent }) =>
      onBroadcastQualityChanged?.(nativeEvent[BroadcastQualityChangedHandler]);

  const onAudioSessionInterruptedHandler: ICameraNativeViewProps['onAudioSessionInterrupted'] =
    () => onAudioSessionInterrupted?.();

  const onAudioSessionResumedHandler: ICameraNativeViewProps['onAudioSessionResumed'] =
    () => onAudioSessionResumed?.();

  const onMediaServicesWereLostHandler: ICameraNativeViewProps['onMediaServicesWereLost'] =
    () => onMediaServicesWereLost?.();

  const onMediaServicesWereResetHandler: ICameraNativeViewProps['onMediaServicesWereReset'] =
    () => onMediaServicesWereReset?.();

  return (
    <RCTIVSBroadcastCameraView
      {...restProps}
      ref={nativeViewRef}
      logLevel={logLevel}
      sessionLogLevel={sessionLogLevel}
      cameraPreviewAspectMode={cameraPreviewAspectMode}
      isCameraPreviewMirrored={isCameraPreviewMirrored}
      cameraPosition={cameraPosition}
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
});

export default IVSBroadcastCameraView;
