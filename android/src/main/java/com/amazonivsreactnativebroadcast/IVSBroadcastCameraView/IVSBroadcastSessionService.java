package com.amazonivsreactnativebroadcast.IVSBroadcastCameraView;

import com.amazonaws.ivs.broadcast.*;

import androidx.annotation.Nullable;

import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.uimanager.ThemedReactContext;

@FunctionalInterface
interface CameraPreviewHandler {
    void run(ImagePreviewView cameraPreview);
}

// Official documentation: https://aws.github.io/amazon-ivs-broadcast-docs/1.2.1/android/reference/com/amazonaws/ivs/broadcast/BroadcastSession.Listener.html#onDeviceAdded(com.amazonaws.ivs.broadcast.Device.Descriptor)
// Guide: https://docs.aws.amazon.com/ivs/latest/userguide//broadcast-android.html
public class IVSBroadcastSessionService {
    private ThemedReactContext mReactContext;
    private boolean isInitialized = false;
    private BroadcastSession broadcastSession;
    private BroadcastSession.Listener broadcastSessionListener;
    private Device currentCameraDevice;
    private boolean isCameraPreviewMirrored = false;
    private BroadcastConfiguration.AspectMode cameraPreviewAspectMode = BroadcastConfiguration.AspectMode.NONE;
    private Device.Descriptor.Position initialCameraPosition = Device.Descriptor.Position.BACK;

    // Default broadcast session config
    private BroadcastConfiguration config = new BroadcastConfiguration();

    private void checkBroadcastSessionOrThrow() {
        if (broadcastSession == null) {
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

    private ImagePreviewView getCameraPreview(Device device) {
        ImagePreviewView preview = ((ImageDevice) device).getPreviewView(cameraPreviewAspectMode);
        preview.setMirrored(isCameraPreviewMirrored);

        return preview;
    }

    private Device.Descriptor[] getInitialDeviceDescriptors() {
        return initialCameraPosition == Device.Descriptor.Position.BACK
                ? Presets.Devices.BACK_CAMERA(mReactContext)
                : Presets.Devices.FRONT_CAMERA(mReactContext);
    }

    public IVSBroadcastSessionService(ThemedReactContext reactContext) {
        mReactContext = reactContext;
    }

    public void init() {
        if (isInitialized) return;

        broadcastSession = new BroadcastSession(
                mReactContext,
                broadcastSessionListener,
                config,
                getInitialDeviceDescriptors()
        );

        isInitialized = true;
    }

    public boolean isInitialized() {
        return isInitialized;
    }

    public void getCameraPreviewAsync(CameraPreviewHandler callback) {
        checkBroadcastSessionOrThrow();

        broadcastSession.awaitDeviceChanges(() -> {
            for (Device device : broadcastSession.listAttachedDevices()) {
                Device.Descriptor desc = device.getDescriptor();
                if (desc.type == Device.Descriptor.DeviceType.CAMERA &&
                        desc.position == initialCameraPosition) {
                    currentCameraDevice = device;
                    callback.run(getCameraPreview(device));
                    break;
                }
            }
        });
    }

    public boolean isReady() {
        checkBroadcastSessionOrThrow();
        return broadcastSession.isReady();
    }

    public void setSessionLogLevel(@Nullable String sessionLogLevel) {
        checkBroadcastSessionOrThrow();
        sessionLogLevel = sessionLogLevel != null ? sessionLogLevel : "error";
        broadcastSession.setLogLevel(getLogLevel(sessionLogLevel));
    }

    public void start(@Nullable String ivsRTMPSUrl, @Nullable String ivsStreamKey) {
         checkBroadcastSessionOrThrow();
         broadcastSession.start(ivsRTMPSUrl, ivsStreamKey);
    }

    public void stop() {
        checkBroadcastSessionOrThrow();
        broadcastSession.stop();
    }

    public void releaseResources() {
        checkBroadcastSessionOrThrow();
        broadcastSession.release();
    }

    public void swapCamera(CameraPreviewHandler callback) {
        checkBroadcastSessionOrThrow();
        for (Device.Descriptor device : broadcastSession.listAvailableDevices(mReactContext)) {
            if (device.type == Device.Descriptor.DeviceType.CAMERA && device.position != currentCameraDevice.getDescriptor().position) {
                broadcastSession.exchangeDevices(currentCameraDevice, device, newCameraDevice -> {
                    currentCameraDevice = newCameraDevice;
                    callback.run(getCameraPreview(newCameraDevice));
                });
            }
        }
    }

    public void setLogLevel(String logLevel) {
        config = config.changing($ -> {
            $.logLevel = getLogLevel(logLevel);
            return $;
        });
    }

    public void setCameraPosition(String cameraPositionName) {
        initialCameraPosition = getCameraPosition(cameraPositionName);
    }

    public void setCameraPreviewAspectMode(String cameraPreviewAspectModeName) {
        cameraPreviewAspectMode = getAspectMode(cameraPreviewAspectModeName);
    }

    public void setIsCameraPreviewMirrored(boolean isPreviewMirrored) {
        isCameraPreviewMirrored = isPreviewMirrored;
    }

    public void setListener(BroadcastSession.Listener broadcastListener) {
        broadcastSessionListener = broadcastListener;
    }

    public void setVideoConfig(ReadableMap videoConfig) {
        if (videoConfig.hasKey("width")
                && videoConfig.hasKey("height")
                && videoConfig.hasKey("bitrate")
                && videoConfig.hasKey("targetFrameRate")
                && videoConfig.hasKey("keyframeInterval")
        ) {
            config = config.changing($ -> {
                if (videoConfig.hasKey("isBFrames")) {
                    $.video.setUseBFrames(videoConfig.getBoolean("isBFrames"));
                }
                if (videoConfig.hasKey("isAutoBitrate")) {
                    $.video.setUseAutoBitrate(videoConfig.getBoolean("isAutoBitrate"));
                }
                if (videoConfig.hasKey("maxBitrate")) {
                    $.video.setMaxBitrate(videoConfig.getInt("maxBitrate"));
                }
                if (videoConfig.hasKey("minBitrate")) {
                    $.video.setMinBitrate(videoConfig.getInt("minBitrate"));
                }

                $.video.setSize(videoConfig.getInt("width"), videoConfig.getInt("height"));
                $.video.setInitialBitrate(videoConfig.getInt("bitrate"));
                $.video.setTargetFramerate(videoConfig.getInt("targetFrameRate"));
                $.video.setKeyframeInterval(videoConfig.getInt("keyframeInterval"));

                return $;
            });
        } else {
            // https://docs.aws.amazon.com/ivs/latest/userguide/streaming-config.html
            throw new RuntimeException("The following properties are required for the video config, since they are interrelated: 'width', 'height', 'bitrate', 'keyframeInterval', 'targetFrameRate'." +
                    " See https://docs.aws.amazon.com/ivs/latest/userguide/streaming-config.html - Resolution/Bitrate/FPS section please."
            );
        }
    }

    public void setAudioConfig(ReadableMap audioConfig) {
        config = config.changing($ -> {
            if (audioConfig.hasKey("bitrate")) {
                $.audio.setBitrate(audioConfig.getInt("bitrate"));
            }
            if (audioConfig.hasKey("channels")) {
                $.audio.setChannels(audioConfig.getInt("channels"));
            }

            return $;
        });
    }
}
