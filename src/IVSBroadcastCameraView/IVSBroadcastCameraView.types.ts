import type { Component, ComponentType } from 'react';
import type { NativeSyntheticEvent, ViewStyle, StyleProp } from 'react-native';

export type ExtractComponentProps<T> = T extends
  | ComponentType<infer P>
  | Component<infer P>
  ? P
  : never;

export enum Command {
  Start = 'START',
  Stop = 'STOP',
  /**
   * @deprecated in favor of {@link CameraPosition}
   */
  SwapCamera = 'SWAP_CAMERA',
}

export enum StateStatusEnum {
  INVALID = 0,
  DISCONNECTED = 1,
  CONNECTING = 2,
  CONNECTED = 3,
  ERROR = 4,
}

export enum NetworkHealthEnum {
  EXCELLENT = 0,
  HIGH = 1,
  MEDIUM = 2,
  LOW = 3,
  BAD = 4,
}

export enum BroadcastQualityEnum {
  NEAR_MAXIMUM = 0,
  HIGH = 1,
  MEDIUM = 2,
  LOW = 3,
  NEAR_MINIMUM = 4,
}

export type StateStatusUnion = keyof typeof StateStatusEnum;

export type BroadcastQuality = keyof typeof BroadcastQualityEnum;

export type NetworkHealth = keyof typeof NetworkHealthEnum;

export type LogLevel = 'debug' | 'error' | 'info' | 'warning';

export type CameraPosition = 'front' | 'back';

export type CameraPreviewAspectMode = 'fit' | 'fill' | 'none';

type AudioChannel = 1 | 2;

type AudioQuality = 'minimum' | 'low' | 'medium' | 'high' | 'maximum';

type KeyframeInterval = 1 | 2 | 3 | 4 | 5;

type AudioSessionStrategy =
  | 'recordOnly'
  | 'playAndRecord'
  | 'playAndRecordDefaultToSpeaker'
  | 'noAction';

type ConfigurationPreset =
  | 'standardPortrait'
  | 'standardLandscape'
  | 'basicPortrait'
  | 'basicLandscape';

type AutomaticBitrateProfile = 'conservative' | 'fastIncrease';

interface IEventHandler<T extends Record<string, unknown>> {
  (event: NativeSyntheticEvent<T>): void;
}

interface IBaseTransmissionStatistics {
  readonly rtt: number;
  readonly recommendedBitrate: number;
  readonly measuredBitrate: number;
}

interface INativeTransmissionStatistics extends IBaseTransmissionStatistics {
  readonly networkHealth: number | NetworkHealth;
  readonly broadcastQuality: number | BroadcastQuality;
}

export interface ITransmissionStatistics extends IBaseTransmissionStatistics {
  readonly networkHealth: NetworkHealth;
  readonly broadcastQuality: BroadcastQuality;
}

export interface IBroadcastSessionError {
  readonly code: string;
  readonly type: string;
  readonly source: string;
  readonly detail: string;
  readonly isFatal: boolean;
  readonly sessionId: string;
}

export interface IAudioStats {
  readonly peak: number;
  readonly rms: number;
}

interface IVideoConfig {
  readonly width?: number;
  readonly height?: number;
  readonly bitrate?: number;
  readonly targetFrameRate?: number;
  readonly keyframeInterval?: KeyframeInterval;
  readonly isBFrames?: boolean;
  readonly isAutoBitrate?: boolean;
  readonly autoBitrateProfile?: AutomaticBitrateProfile;
  readonly maxBitrate?: number;
  readonly minBitrate?: number;
}

interface IAudioConfig {
  readonly bitrate?: number;
  readonly channels?: AudioChannel;
  readonly audioSessionStrategy?: AudioSessionStrategy;
  readonly quality?: AudioQuality;
}

interface IConnectedStateMetadata {
  readonly sessionId: string;
}

export type StateChangedMetadata = IConnectedStateMetadata;

export interface INativeEventHandlers {
  onError: IEventHandler<Readonly<{ message: string }>>;
  onBroadcastError: IEventHandler<
    Readonly<{
      exception: {
        readonly code?: number;
        readonly type?: string;
        readonly source?: string;
        readonly detail?: string;
        readonly isFatal?: boolean;
        readonly sessionId?: string;
      };
    }>
  >;
  onIsBroadcastReady: IEventHandler<Readonly<{ isReady: boolean }>>;
  onBroadcastAudioStats: IEventHandler<Readonly<{ audioStats: IAudioStats }>>;
  onBroadcastStateChanged: IEventHandler<
    Readonly<{
      stateStatus: StateStatusUnion | number;
      metadata?: StateChangedMetadata;
    }>
  >;
  /**
   * @deprecated in favor of onTransmissionStatisticsChanged
   */
  onBroadcastQualityChanged: IEventHandler<Readonly<{ quality: number }>>;
  /**
   * @deprecated in favor of onTransmissionStatisticsChanged
   */
  onNetworkHealthChanged: IEventHandler<Readonly<{ networkHealth: number }>>;
  onTransmissionStatisticsChanged: IEventHandler<
    Readonly<{ statistics: INativeTransmissionStatistics }>
  >;
  onAudioSessionInterrupted(): void;
  onAudioSessionResumed(): void;
  onMediaServicesWereLost(): void;
  onMediaServicesWereReset(): void;
}

export interface IIVSBroadcastCameraNativeViewProps
  extends IBaseProps,
    INativeEventHandlers {
  readonly style?: StyleProp<ViewStyle>;
  readonly testID?: string;
}

interface IBaseProps {
  readonly rtmpsUrl?: string;
  readonly streamKey?: string;
  readonly configurationPreset?: ConfigurationPreset;
  readonly videoConfig?: IVideoConfig;
  readonly audioConfig?: IAudioConfig;
  readonly logLevel?: LogLevel;
  readonly sessionLogLevel?: LogLevel;
  readonly cameraPreviewAspectMode?: CameraPreviewAspectMode;
  readonly isCameraPreviewMirrored?: boolean;
  readonly cameraPosition?: CameraPosition;
  readonly isMuted?: boolean;
}

export interface IEventHandlers {
  onError?(errorMessage: string): void;
  onBroadcastError?(error: IBroadcastSessionError): void;
  onIsBroadcastReady?(isReady: boolean): void;
  onBroadcastAudioStats?(audioStats: IAudioStats): void;
  onBroadcastStateChanged?(
    stateStatus: StateStatusUnion,
    metadata?: StateChangedMetadata
  ): void;
  /**
   * @deprecated in favor of onTransmissionStatisticsChanged
   */
  onBroadcastQualityChanged?(quality: number): void;
  /**
   * @deprecated in favor of onTransmissionStatisticsChanged
   */
  onNetworkHealthChanged?(networkHealth: number): void;
  onTransmissionStatisticsChanged?(
    transmissionStatistics: ITransmissionStatistics
  ): void;
  onAudioSessionInterrupted?(): void;
  onAudioSessionResumed?(): void;
  onMediaServicesWereLost?(): void;
  onMediaServicesWereReset?(): void;
}

export interface IIVSBroadcastCameraViewProps
  extends IBaseProps,
    IEventHandlers {
  readonly style?: StyleProp<ViewStyle>;
  readonly testID?: string;
}

type StartMethodOptions = Pick<IBaseProps, 'rtmpsUrl' | 'streamKey'>;

export interface IIVSBroadcastCameraView {
  start(options?: StartMethodOptions): void;
  stop(): void;
  /**
   * @deprecated in favor of {@link CameraPosition}
   */
  swapCamera(): void;
}
