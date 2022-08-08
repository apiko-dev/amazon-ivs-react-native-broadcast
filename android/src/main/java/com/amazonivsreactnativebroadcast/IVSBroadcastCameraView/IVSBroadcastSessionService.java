package com.amazonivsreactnativebroadcast.IVSBroadcastCameraView;

import com.amazonaws.ivs.broadcast.*;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.uimanager.ThemedReactContext;

@FunctionalInterface
interface CameraPreviewHandler {
  void run(ImagePreviewView cameraPreview);
}

// Guide: https://docs.aws.amazon.com/ivs/latest/userguide//broadcast-android.html
public class IVSBroadcastSessionService {
  private ThemedReactContext mReactContext;

  private boolean isInitialized = false;

  private boolean isInitialMuted = false;
  private Device.Descriptor.Position initialCameraPosition = Device.Descriptor.Position.BACK;
  private BroadcastConfiguration.LogLevel initialSessionLogLevel = BroadcastConfiguration.LogLevel.ERROR;
  private boolean isCameraPreviewMirrored = false;
  private BroadcastConfiguration.AspectMode cameraPreviewAspectMode = BroadcastConfiguration.AspectMode.NONE;
  private ReadableMap customVideoConfig;
  private ReadableMap customAudioConfig;

  private Device.Descriptor attachedCameraDescriptor;
  private Device.Descriptor attachedMicrophoneDescriptor;

  private BroadcastSession broadcastSession;
  private BroadcastSession.Listener broadcastSessionListener;
  private BroadcastConfiguration config = new BroadcastConfiguration();

  private void checkBroadcastSessionOrThrow() {
    if (broadcastSession == null || !isInitialized) {
      throw new RuntimeException("Broadcast session is not initialized.");
    }
  }

  private BroadcastConfiguration.LogLevel getLogLevel(String logLevelName) {
    switch (logLevelName) {
      case "debug": {
        return BroadcastConfiguration.LogLevel.DEBUG;
      }
      case "error": {
        return BroadcastConfiguration.LogLevel.ERROR;
      }
      case "info": {
        return BroadcastConfiguration.LogLevel.INFO;
      }
      case "warning": {
        return BroadcastConfiguration.LogLevel.WARNING;
      }
      default: {
        throw new RuntimeException("Does not support log level: " + logLevelName);
      }
    }
  }

  private BroadcastConfiguration.AspectMode getAspectMode(String aspectModeName) {
    switch (aspectModeName) {
      case "fit": {
        return BroadcastConfiguration.AspectMode.FIT;
      }
      case "fill": {
        return BroadcastConfiguration.AspectMode.FILL;
      }
      case "none": {
        return BroadcastConfiguration.AspectMode.NONE;
      }
      default: {
        throw new RuntimeException("Does not support aspect mode: " + aspectModeName);
      }
    }
  }

  private Device.Descriptor.Position getCameraPosition(String cameraPositionName) {
    switch (cameraPositionName) {
      case "front": {
        return Device.Descriptor.Position.FRONT;
      }
      case "back": {
        return Device.Descriptor.Position.BACK;
      }
      default: {
        throw new RuntimeException("Does not support camera position: " + cameraPositionName);
      }
    }
  }

  private BroadcastConfiguration getConfigurationPreset(String configurationPresetName) {
    switch (configurationPresetName) {
      case "standardPortrait": {
        return Presets.Configuration.STANDARD_PORTRAIT;
      }
      case "standardLandscape": {
        return Presets.Configuration.STANDARD_LANDSCAPE;
      }
      case "basicPortrait": {
        return Presets.Configuration.BASIC_PORTRAIT;
      }
      case "basicLandscape": {
        return Presets.Configuration.BASIC_LANDSCAPE;
      }
      default: {
        throw new RuntimeException("Does not support configuration preset: " + configurationPresetName);
      }
    }
  }

  private ImagePreviewView getCameraPreview() {
    ImagePreviewView preview = broadcastSession.getPreviewView(cameraPreviewAspectMode);
    preview.setMirrored(isCameraPreviewMirrored);

    return preview;
  }

  private Device.Descriptor[] getInitialDeviceDescriptorList() {
    return initialCameraPosition == Device.Descriptor.Position.BACK
      ? Presets.Devices.BACK_CAMERA(mReactContext)
      : Presets.Devices.FRONT_CAMERA(mReactContext);
  }

  private void setCustomVideoConfig() {
    if (customVideoConfig != null) {
      config = config.changing($ -> {
        boolean isWidth = customVideoConfig.hasKey("width");
        boolean isHeight = customVideoConfig.hasKey("height");
        if (isWidth || isHeight) {
          if (isWidth && isHeight) {
            $.video.setSize(
              customVideoConfig.getInt("width"),
              customVideoConfig.getInt("height")
            );
          } else {
            throw new RuntimeException("The `width` and `height` are interrelated and thus can not be used separately.");
          }
        }

        if (customVideoConfig.hasKey("bitrate")) {
          $.video.setInitialBitrate(customVideoConfig.getInt("bitrate"));
        }
        if (customVideoConfig.hasKey("targetFrameRate")) {
          $.video.setTargetFramerate(customVideoConfig.getInt("targetFrameRate"));
        }
        if (customVideoConfig.hasKey("keyframeInterval")) {
          $.video.setKeyframeInterval(customVideoConfig.getInt("keyframeInterval"));
        }
        if (customVideoConfig.hasKey("isBFrames")) {
          $.video.setUseBFrames(customVideoConfig.getBoolean("isBFrames"));
        }
        if (customVideoConfig.hasKey("isAutoBitrate")) {
          $.video.setUseAutoBitrate(customVideoConfig.getBoolean("isAutoBitrate"));
        }
        if (customVideoConfig.hasKey("maxBitrate")) {
          $.video.setMaxBitrate(customVideoConfig.getInt("maxBitrate"));
        }
        if (customVideoConfig.hasKey("minBitrate")) {
          $.video.setMinBitrate(customVideoConfig.getInt("minBitrate"));
        }
        return $;
      });
    }
  }

  private void setCustomAudioConfig() {
    if (customAudioConfig != null) {
      config = config.changing($ -> {
        if (customAudioConfig.hasKey("bitrate")) {
          $.audio.setBitrate(customAudioConfig.getInt("bitrate"));
        }
        if (customAudioConfig.hasKey("channels")) {
          $.audio.setChannels(customAudioConfig.getInt("channels"));
        }
        return $;
      });
    }
  }

  private void swapCameraAsync(CameraPreviewHandler callback) {
    checkBroadcastSessionOrThrow();

    broadcastSession.awaitDeviceChanges(() -> {
      for (Device.Descriptor deviceDescriptor : broadcastSession.listAvailableDevices(mReactContext)) {
        if (deviceDescriptor.type == Device.Descriptor.DeviceType.CAMERA && deviceDescriptor.position != attachedCameraDescriptor.position) {
          broadcastSession.exchangeDevices(attachedCameraDescriptor, deviceDescriptor, newCamera -> {
            attachedCameraDescriptor = newCamera.getDescriptor();
            callback.run(getCameraPreview());
          });
        }
      }
    });
  }

  private void muteAsync(boolean isMuted) {
    broadcastSession.awaitDeviceChanges(() -> {
      for (Device device : broadcastSession.listAttachedDevices()) {
        Device.Descriptor deviceDescriptor = device.getDescriptor();
        if (deviceDescriptor.type == Device.Descriptor.DeviceType.MICROPHONE && deviceDescriptor.urn.equals(attachedMicrophoneDescriptor.urn)) {
          Float gain = isMuted ? 0.0F : 1.0F;
          ((AudioDevice) device).setGain(gain);
          break;
        }
      }
    });
  }

  private void preInitialization() {
    setCustomVideoConfig();
    setCustomAudioConfig();
  }

  private void postInitialization() {
    broadcastSession.setLogLevel(initialSessionLogLevel);
    if (isInitialMuted) {
      muteAsync(isInitialMuted);
    }
  }

  private void saveInitialDevicesDescriptor(@NonNull Device.Descriptor[] deviceDescriptors) {
    for (Device.Descriptor deviceDescriptor : deviceDescriptors) {
      if (deviceDescriptor.type == Device.Descriptor.DeviceType.CAMERA) {
        attachedCameraDescriptor = deviceDescriptor;
      } else if (deviceDescriptor.type == Device.Descriptor.DeviceType.MICROPHONE) {
        attachedMicrophoneDescriptor = deviceDescriptor;
      }
    }
  }

  public IVSBroadcastSessionService(ThemedReactContext reactContext) {
    mReactContext = reactContext;
  }

  public String init() {
    if (isInitialized) return broadcastSession.getSessionId();

    preInitialization();

    broadcastSession = new BroadcastSession(
      mReactContext,
      broadcastSessionListener,
      config,
      getInitialDeviceDescriptorList()
    );

    saveInitialDevicesDescriptor(getInitialDeviceDescriptorList());
    isInitialized = true;

    postInitialization();

    return broadcastSession.getSessionId();
  }

  public void releaseResources() {
    checkBroadcastSessionOrThrow();
    broadcastSession.release();
  }

  public boolean isInitialized() {
    return isInitialized;
  }

  public boolean isReady() {
    checkBroadcastSessionOrThrow();
    return broadcastSession.isReady();
  }

  public void start(@Nullable String ivsRTMPSUrl, @Nullable String ivsStreamKey) {
    checkBroadcastSessionOrThrow();
    broadcastSession.start(ivsRTMPSUrl, ivsStreamKey);
  }

  public void stop() {
    checkBroadcastSessionOrThrow();
    broadcastSession.stop();
  }

  @Deprecated
  public void swapCamera(CameraPreviewHandler callback) {
    swapCameraAsync(callback);
  }

  public void getCameraPreviewAsync(CameraPreviewHandler callback) {
    checkBroadcastSessionOrThrow();
    broadcastSession.awaitDeviceChanges(() -> {
      callback.run(getCameraPreview());
    });
  }

  public void setCameraPosition(String cameraPositionName, CameraPreviewHandler callback) {
    if (isInitialized) {
      swapCameraAsync(callback);
    } else {
      initialCameraPosition = getCameraPosition(cameraPositionName);
    }
  }

  public void setCameraPreviewAspectMode(String cameraPreviewAspectModeName, CameraPreviewHandler callback) {
    cameraPreviewAspectMode = getAspectMode(cameraPreviewAspectModeName);
    if (isInitialized) {
      getCameraPreviewAsync(callback);
    }
  }

  public void setIsCameraPreviewMirrored(boolean isPreviewMirrored, CameraPreviewHandler callback) {
    isCameraPreviewMirrored = isPreviewMirrored;
    if (isInitialized) {
      getCameraPreviewAsync(callback);
    }
  }

  public void setIsMuted(boolean isMuted) {
    if (isInitialized) {
      checkBroadcastSessionOrThrow();
      muteAsync(isMuted);
    } else {
      isInitialMuted = isMuted;
    }
  }

  public void setSessionLogLevel(String sessionLogLevelName) {
    BroadcastConfiguration.LogLevel sessionLogLevel = getLogLevel(sessionLogLevelName);
    if (isInitialized) {
      checkBroadcastSessionOrThrow();
      broadcastSession.setLogLevel(sessionLogLevel);
    } else {
      initialSessionLogLevel = sessionLogLevel;
    }
  }

  public void setLogLevel(String logLevel) {
    config = config.changing($ -> {
      $.logLevel = getLogLevel(logLevel);
      return $;
    });
  }

  public void setListener(BroadcastSession.Listener broadcastListener) {
    broadcastSessionListener = broadcastListener;
  }

  public void setConfigurationPreset(String configurationPreset) {
    config = getConfigurationPreset(configurationPreset);
  }

  public void setVideoConfig(ReadableMap videoConfig) {
    customVideoConfig = videoConfig;
  }

  public void setAudioConfig(ReadableMap audioConfig) {
    customAudioConfig = audioConfig;
  }
}
