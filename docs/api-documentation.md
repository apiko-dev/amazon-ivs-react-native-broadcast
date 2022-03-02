# **API Documentation**

## `IVSBroadcastCameraView` component

### _**Props**_

#### ⚫ `style`

Style of `IVSBroadcastCameraView` component. 

| Type | Required | Platform |
| :---: | :---: | :---: |
| `StyleProp<ViewStyle>` | No | iOS, Android |

#### ⚫ `testID`

Used to locate `IVSBroadcastCameraView` component in the end-to-end tests.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `string` | No | iOS, Android |

#### ⚫ `rtmpsUrl`

The RTMPS endpoint provided by IVS.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `string` | Yes | iOS, Android |

#### ⚫ `streamKey`

The broadcaster’s stream key that has been provided by IVS.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `string` | Yes | iOS, Android |

#### ⚫ `videoConfig`

A configuration object describing the desired format of the final output Video stream.

⚠️ _Changing any properties on this object after providing it to `IVSBroadcastCameraView` component will not have any effect. A copy of the configuration is made and kept internally._

| Type | Required | Platform |
| :---: | :---: | :---: |
| [`IVideoConfig`](./types.md#ivideoconfig) | No | iOS, Android |

_**Default video config:**_
| Key | Value |
| :---: | :---: |
| `width` | `720` |
| `height` | `1280` |
| `bitrate` | `2100000` |
| `targetFrameRate` | `30` |
| `keyframeInterval` | `2` |
| `isBFrames` | `true` |
| `isAutoBitrate` | `true` |
| `maxBitrate` | `6000000` |
| `minBitrate` | `300000` |

#### ⚫ `audioConfig`

A configuration object describing the desired format of the final output Audio stream.

⚠️ _Changing any properties on this object after providing it to `IVSBroadcastCameraView` component will not have any effect. A copy of the configuration is made and kept internally._

| Type | Required | Platform |
| :---: | :---: | :---: |
| [`IAudioConfig`](./types.md#iaudioconfig) | No | iOS, Android |

_**Default audio config:**_
| Key | Value |
| :---: | :---: |
| `bitrate` | `96000` |
| `channels` | `2` |
| `audioSessionStrategy` | `playAndRecord` |

#### ⚫ `logLevel`

 In order to catch logs at a more granular level than `Error` during the initialization process, use this property instead of the [`sessionLogLevel`](#%E2%9A%AB-sessionloglevel).
 
| Type | Required | Platform | Default value |
| :---: | :---: | :---: | :---: |
| [`LogLevel`](./types.md#loglevel) | No | iOS, Android | `error` |

#### ⚫ `sessionLogLevel`

Logging level for the broadcast session.

| Type | Required | Platform | Default value |
| :---: | :---: | :---: | :---: |
| [`LogLevel`](./types.md#loglevel) | No | iOS, Android | `error` |

#### ⚫ `cameraPreviewAspectMode`

 Determines how view's aspect ratio will be maintained.
 
| Type | Required | Platform | Default value |
| :---: | :---: | :---: | :---: |
| [`CameraPreviewAspectMode`](./types.md#camerapreviewaspectmode) | No | iOS, Android | `none` |

#### ⚫ `isCameraPreviewMirrored`

Flips the camera preview horizontally.

| Type | Required | Platform | Default value |
| :---: | :---: | :---: | :---: |
| `boolean` | No | iOS, Android | `false` |

#### ⚫ `cameraPosition`

The position of the input device relative to the host device.

| Type | Required | Platform | Default value |
| :---: | :---: | :---: | :---: |
| [`CameraPosition`](./types.md#cameraposition) | No | iOS, Android | `back` |

### _**Handlers**_

#### ⚫ `onError`

 Indicates that module' internal error occurred.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onError(errorMessage: string): void` | No | iOS, Android |
 
#### ⚫  `onBroadcastError`

Indicates that broadcast session error occurred. Errors may or may not be fatal. In the case of a fatal error the broadcast session moves into `DISCONNECTED` [state status](./types.md#statestatusunion).

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onBroadcastError(error: IBroadcastSessionError): void` | No | iOS, Android |

👉 See [`IBroadcastSessionError`](./types.md#ibroadcastsessionerror) type.

#### ⚫  `onIsBroadcastReady`

Fires(once) when initialization (including adding camera preview to the view hierarchy) is done.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onIsBroadcastReady(isReady: boolean): void` | No | iOS, Android |

#### ⚫  `onBroadcastAudioStats`

Periodically called with audio `peak` and `rms` in `dBFS`.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onBroadcastAudioStats(audioStats: IAudioStats): void` | No | iOS, Android |

👉 See [`IAudioStats`](./types.md#iaudiostats) type.

#### ⚫ `onBroadcastStateChanged`

Indicates that the broadcast state changed.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onBroadcastStateChanged(stateStatus: StateStatusUnion): void` | No | iOS, Android |

👉 See [`StateStatusUnion`](./types.md#statestatusunion) type.

#### ⚫ `onBroadcastQualityChanged`

Represents the quality of the stream.

`quality` is a number between `0` and `1` that represents the quality of the stream based on minimum and maximum bitrate provided in the [`videoConfig`](#%E2%9A%AB-videoconfig). `0` means the stream is at the lowest possible quality, or streaming is not possible at all. `1` means the bitrate is near the maximum allowed.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onBroadcastQualityChanged(quality: number): void` | No | iOS, Android |

#### ⚫ `onNetworkHealthChanged`

Provides updates when the instantaneous quality of the network changes.

`networkHealth` is a number between `0` and `1` that represents the current health of the network. `0` means the network is struggling to keep up and the broadcast may be experiencing latency spikes. The SDK may also reduce the quality of the broadcast on low values in order to keep it stable, depending on the minimum allowed bitrate in the [`videoConfig`](#%E2%9A%AB-videoconfig). A value of `1` means the network is easily able to keep up with the current demand and the SDK will be trying to increase the broadcast quality over time, depending on the maximum allowed bitrate. Lower values like `0.5` are not necessarily bad, it just means the network is being saturated, but it is still able to keep up.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onNetworkHealthChanged(networkHealth: number): void` | No | iOS, Android |

#### ⚫ `onAudioSessionInterrupted`

Indicates that audio session has been interrupted.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onAudioSessionInterrupted(): void` | No | iOS |

⚠️ There are several scenarios where the SDK may not have exclusive access to audio-input hardware. Some example scenarios that you need to handle are:
* User receives a phone call or FaceTime call
* User activates Siri

#### ⚫ `onAudioSessionResumed`

Indicates that audio session has been resumed (after interrupted).

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onAudioSessionResumed(): void` | No | iOS |

#### ⚫ `onMediaServicesWereLost`

>_In very rare cases, the entire media subsystem on an iOS device will crash. In this scenario, the SDK can no longer broadcast._

Indicates that the media server services are terminated.
Respond by stopping and completely deallocating broadcast session. All internal components used by the broadcast session will be invalidated.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onMediaServicesWereLost(): void` | No | iOS |

#### ⚫ `onMediaServicesWereReset`

Indicates that the media server services are reset.
Respond by notifying consumers that they can broadcast again. Depending on the case, you may be able to automatically start broadcasting again at this point.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onMediaServicesWereReset(): void` | No | iOS |

### _**Methods**_

#### ⚫ `start`

Start the configured broadcast session.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `(): void` | No | iOS, Android |

#### ⚫ `stop`

Stop the broadcast session, but do not deallocate resources.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `(): void` | No | iOS, Android |

⚠️ Stopping the stream happens asynchronously while the SDK attempts to gracefully end the broadcast. Observe state changes to know when a new stream could be started. 

#### ⚫ `swapCamera`

Swap back camera to front camera and vice versa.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `(): void` | No | iOS, Android |