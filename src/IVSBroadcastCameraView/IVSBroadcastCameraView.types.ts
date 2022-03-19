import type { NativeSyntheticEvent, ViewStyle, StyleProp } from 'react-native';

export enum Command {
  Start = 'START',
  Stop = 'STOP',
  SwapCamera = 'SWAP_CAMERA',
}

export enum EventPayloadKey {
  ErrorHandler = 'message',
  BroadcastErrorHandler = 'exception',
  IsBroadcastReadyHandler = 'isReady',
  BroadcastAudioStatsHandler = 'audioStats',
  BroadcastQualityChangedHandler = 'quality',
  BroadcastStateChangedHandler = 'stateStatus',
  NetworkHealthChangedHandler = 'networkHealth',
}

export enum StateStatus {
  /**
   * The session is invalid. This is the initial state after creating a session but before starting a stream
   */
  INVALID = 0,
  /**
   * The session has disconnected. After stopping a stream the session should return to this state unless it has errored
   */
  DISCONNECTED = 1,
  /**
   * The session is connecting to the ingest server
   */
  CONNECTING = 2,
  /**
   * The session has connected to the ingest server and is currently sending data
   */
  CONNECTED = 3,
  /**
   * The session has had an error
   */
  ERROR = 4,
}

export type StateStatusUnion = keyof typeof StateStatus;

type LogLevel = 'debug' | 'error' | 'info' | 'warning';

type CameraPosition = 'front' | 'back';

type CameraPreviewAspectMode = 'fit' | 'fill' | 'none';

type AudioChannel = 1 | 2;

type AudioSessionStrategy = 'recordOnly' | 'playAndRecord' | 'noAction';

interface IEventHandler<T extends Record<string, unknown>> {
  (event: NativeSyntheticEvent<T>): void;
}

export interface IBroadcastSessionError {
  readonly code: string;
  readonly type: string;
  readonly source: string;
  readonly detail: string;
  readonly isFatal: boolean;
}

export interface IAudioStats {
  /**
   * Audio Peak over the time period
   */
  readonly peak: number;
  /**
   * Audio RMS over the time period
   */
  readonly rms: number;
}

interface IVideoConfig {
  /**
   * The smallest size is 160, and the largest is either 1080 or 1920
   */
  readonly width: number;
  /**
   * The smallest size is 160, and the largest is either 1080 or 1920
   */
  readonly height: number;
  /**
   * The initial bitrate for the output video stream.
   * !! The value must be between 100_000(100k) and 8_500_000(8500k)
   */
  readonly bitrate: number;
  /**
   * The target framerate of the output video stream.
   * !! The value must be between 10 and 60
   */
  readonly targetFrameRate: number;
  /**
   * The keyframe interval for the output video stream.
   * !! The value must be between 1 and 10
   */
  readonly keyframeInterval: number;
  /**
   * Whether the output video stream uses B (Bidirectional predicted picture) frames
   */
  readonly isBFrames?: boolean;
  /**
   * Whether the output video stream will automatically adjust the bitrate based on network conditions
   */
  readonly isAutoBitrate?: boolean;
  /**
   * The maximum bitrate for the output video stream.
   * !! The value must be between 100_000(100k) and 8_500_000(8500k)
   */
  readonly maxBitrate?: number;
  /**
   * The minimum bitrate for the output video stream.
   * !! The value must be between 100_000(100k) and 8_500_000(8500k)
   */
  readonly minBitrate?: number;
}

interface IAudioConfig {
  /**
   * The audio bitrate for the output audio stream
   * !! The value must be greater than 64k and less than 160k
   */
  readonly bitrate?: number;
  /**
   * The number of channels for the output audio stream
   */
  readonly channels?: AudioChannel;
  /**
   * A value representing how the broadcast session will interact with AVAudioSession
   */
  readonly audioSessionStrategy?: AudioSessionStrategy;
}

interface IIVSBroadcastCameraViewBaseProps {
  readonly style?: StyleProp<ViewStyle>;
  /**
   * Used to locate the view in end-to-end tests
   */
  readonly testID?: string;
  /**
   * The RTMPS endpoint provided by IVS
   */
  readonly rtmpsUrl: string;
  /**
   * The broadcaster’s stream key that has been provided by IVS
   */
  readonly streamKey: string;
  /**
   * A configuration object describing the desired format of the final output Video stream
   */
  readonly videoConfig?: IVideoConfig;
  /**
   * A configuration object describing the desired format of the final output Audio stream
   */
  readonly audioConfig?: IAudioConfig;
  /**
   * In order to catch logs at a more granular level than {@link LogLevel.Error} during the initialization process,
   * use 'logLevel' property instead of the 'sessionLogLevel'
   */
  readonly logLevel?: LogLevel;
  /**
   * Logging level for the broadcast session
   */
  readonly sessionLogLevel?: LogLevel;
  /**
   * Determines how view's aspect ratio will be maintained
   */
  readonly cameraPreviewAspectMode?: CameraPreviewAspectMode;
  /**
   * Flips the camera preview horizontally
   */
  readonly isCameraPreviewMirrored?: boolean;
  /**
   * The position of the input device relative to the host device
   */
  readonly cameraPosition?: CameraPosition;
}

export interface IIVSBroadcastCameraView {
  /**
   * Start the configured broadcast session
   */
  start(): void;
  /**
   * Stop the broadcast session, but do not deallocate resources.
   * Stopping the stream happens asynchronously while the SDK attempts to gracefully end the broadcast.
   */
  stop(): void;
  /**
   * Swap back camera to front camera and vice versa
   */
  swapCamera(): void;
}

export interface IIVSBroadcastCameraNativeViewProps
  extends IIVSBroadcastCameraViewBaseProps {
  onError: IEventHandler<Readonly<{ message: string }>>;
  onBroadcastError: IEventHandler<
    Readonly<{
      exception: {
        readonly code?: number;
        readonly type?: string;
        readonly source?: string;
        readonly detail?: string;
        readonly isFatal?: boolean;
      };
    }>
  >;
  onIsBroadcastReady: IEventHandler<Readonly<{ isReady: boolean }>>;
  onBroadcastAudioStats: IEventHandler<Readonly<{ audioStats: IAudioStats }>>;
  onBroadcastStateChanged: IEventHandler<
    Readonly<{
      stateStatus: StateStatusUnion | number;
    }>
  >;
  onBroadcastQualityChanged: IEventHandler<Readonly<{ quality: number }>>;
  onNetworkHealthChanged: IEventHandler<Readonly<{ networkHealth: number }>>;
  onAudioSessionInterrupted(): void;
  onAudioSessionResumed(): void;
  onMediaServicesWereReset(): void;
  onMediaServicesWereLost(): void;
}

export interface IIVSBroadcastCameraViewProps
  extends IIVSBroadcastCameraViewBaseProps {
  /**
   * Indicates that module' internal error occurred
   */
  onError?(errorMessage: string): void;
  /**
   * Indicates that broadcast session error occurred. Errors may or may not be fatal.
   * In the case of a fatal error the broadcast session moves into {@link StateStatus.DISCONNECTED} state
   */
  onBroadcastError?(error: IBroadcastSessionError): void;
  /**
   * Fires(once) when initialization (including adding camera preview to the view hierarchy) is done
   */
  onIsBroadcastReady?(isReady: boolean): void;
  /**
   * Periodically called with audio peak and rms in dBFS. Range is -100 (silent) to 0
   */
  onBroadcastAudioStats?(audioStats: IAudioStats): void;
  /**
   * Indicates that the broadcast state changed
   */
  onBroadcastStateChanged?(stateStatus: StateStatusUnion): void;
  /**
   * Represents the quality of the stream based on bitrate minimum and maximum provided on session configuration
   */
  onBroadcastQualityChanged?(quality: number): void;
  /**
   * Provides updates when the instantaneous quality of the network changes.
   */
  onNetworkHealthChanged?(networkHealth: number): void;
  /**
   * Indicates that audio session has been interrupted
   */
  onAudioSessionInterrupted?(): void;
  /**
   * Indicates that audio session has been resumed (after interrupted)
   */
  onAudioSessionResumed?(): void;
  /**
   * Indicates that the media server services are terminated
   */
  onMediaServicesWereLost?(): void;
  /**
   * Indicates that the media server services are reset
   */
  onMediaServicesWereReset?(): void;
}
