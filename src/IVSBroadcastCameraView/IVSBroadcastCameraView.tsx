import React, {
  useRef,
  forwardRef,
  PropsWithChildren,
  useImperativeHandle,
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
  IIVSBroadcastCameraView,
  IIVSBroadcastCameraViewProps,
  IIVSBroadcastCameraNativeViewProps,
} from './IVSBroadcastCameraView.types';

const UNKNOWN = 'unknown';
const NATIVE_VIEW_NAME = 'RCTIVSBroadcastCameraView';

const RCTIVSBroadcastCameraView =
  requireNativeComponent<IIVSBroadcastCameraNativeViewProps>(NATIVE_VIEW_NAME);

const NATIVE_SIDE_COMMANDS =
  UIManager.getViewManagerConfig(NATIVE_VIEW_NAME).Commands;

export const getCommandIdByPlatform = (command: Command) => {
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
  ErrorHandler,
  BroadcastErrorHandler,
  IsBroadcastReadyHandler,
  BroadcastAudioStatsHandler,
  NetworkHealthChangedHandler,
  BroadcastStateChangedHandler,
  BroadcastQualityChangedHandler,
} = EventPayloadKey;

const IVSBroadcastCameraView = forwardRef<
  IIVSBroadcastCameraView,
  PropsWithChildren<IIVSBroadcastCameraViewProps>
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

  useImperativeHandle<IIVSBroadcastCameraView, IIVSBroadcastCameraView>(
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

  const onErrorHandler: IIVSBroadcastCameraNativeViewProps['onError'] = ({
    nativeEvent,
  }) => onError?.(nativeEvent[ErrorHandler]);

  const onBroadcastErrorHandler: IIVSBroadcastCameraNativeViewProps['onBroadcastError'] =
    ({ nativeEvent }) => {
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

  const onIsBroadcastReadyHandler: IIVSBroadcastCameraNativeViewProps['onIsBroadcastReady'] =
    ({ nativeEvent }) =>
      onIsBroadcastReady?.(nativeEvent[IsBroadcastReadyHandler]);

  const onBroadcastAudioStatsHandler: IIVSBroadcastCameraNativeViewProps['onBroadcastAudioStats'] =
    ({ nativeEvent }) =>
      onBroadcastAudioStats?.(nativeEvent[BroadcastAudioStatsHandler]);

  const onBroadcastStateChangedHandler: IIVSBroadcastCameraNativeViewProps['onBroadcastStateChanged'] =
    ({ nativeEvent }) => {
      const incomingStateStatus = nativeEvent[BroadcastStateChangedHandler];
      const outcomingStateStatus = (
        typeof incomingStateStatus === 'number'
          ? StateStatus[incomingStateStatus]
          : incomingStateStatus
      ) as StateStatusUnion;
      onBroadcastStateChanged?.(outcomingStateStatus);
    };

  const onNetworkHealthChangedHandler: IIVSBroadcastCameraNativeViewProps['onNetworkHealthChanged'] =
    ({ nativeEvent }) =>
      onNetworkHealthChanged?.(nativeEvent[NetworkHealthChangedHandler]);

  const onBroadcastQualityChangedHandler: IIVSBroadcastCameraNativeViewProps['onBroadcastQualityChanged'] =
    ({ nativeEvent }) =>
      onBroadcastQualityChanged?.(nativeEvent[BroadcastQualityChangedHandler]);

  const onAudioSessionInterruptedHandler: IIVSBroadcastCameraNativeViewProps['onAudioSessionInterrupted'] =
    () => onAudioSessionInterrupted?.();

  const onAudioSessionResumedHandler: IIVSBroadcastCameraNativeViewProps['onAudioSessionResumed'] =
    () => onAudioSessionResumed?.();

  const onMediaServicesWereLostHandler: IIVSBroadcastCameraNativeViewProps['onMediaServicesWereLost'] =
    () => onMediaServicesWereLost?.();

  const onMediaServicesWereResetHandler: IIVSBroadcastCameraNativeViewProps['onMediaServicesWereReset'] =
    () => onMediaServicesWereReset?.();

  return (
    <RCTIVSBroadcastCameraView
      testID={NATIVE_VIEW_NAME}
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
