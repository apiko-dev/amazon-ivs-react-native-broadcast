import React, { FC, useEffect, useState, useRef, useCallback } from 'react';
import {
  Text,
  Modal,
  View,
  Alert,
  AppState,
  StyleSheet,
  ActivityIndicator,
  TouchableOpacity,
  TouchableOpacityProps,
} from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';

import { rtmpsUrl, streamKey } from '../app.json';
import {
  IAudioStats,
  StateStatusUnion,
  IBroadcastSessionError,
  IVSBroadcastCameraView,
  IIVSBroadcastCameraView,
} from 'amazon-ivs-react-native-broadcast';

enum SessionReadyStatus {
  None = 'NONE',
  Ready = 'READY',
  NotReady = 'NOT_READY',
}

const { None, NotReady, Ready } = SessionReadyStatus;

const INITIAL_BROADCAST_STATE_STATUS = 'INVALID' as const;
const INITIAL_STATE = {
  readyStatus: None,
  stateStatus: INITIAL_BROADCAST_STATE_STATUS,
};
const INITIAL_META_DATA_STATE = {
  audioStats: {
    rms: 0,
    peak: 0,
  },
  streamQuality: 0,
  networkHealth: 0,
};
const VIDEO_CONFIG = {
  width: 1920,
  height: 1080,
  bitrate: 7500000,
  targetFrameRate: 60,
  keyframeInterval: 2,
  isBFrames: true,
  isAutoBitrate: true,
  maxBitrate: 8500000,
  minBitrate: 1500000,
};
const AUDIO_CONFIG = {
  bitrate: 128000,
};

const Spinner = () => <ActivityIndicator size="large" style={s.spinner} />;

const Button: FC<{
  title: string;
  onPress: Exclude<TouchableOpacityProps['onPress'], undefined>;
}> = ({ onPress, title }) => (
  <TouchableOpacity style={s.button} onPress={onPress}>
    <Text style={s.buttonText}>{title}</Text>
  </TouchableOpacity>
);

const App: FC = () => {
  const cameraViewRef = useRef<IIVSBroadcastCameraView>(null);

  const [{ stateStatus, readyStatus }, setState] = useState<{
    readonly stateStatus: StateStatusUnion;
    readonly readyStatus: SessionReadyStatus;
  }>(INITIAL_STATE);

  const [{ audioStats, networkHealth, streamQuality }, setMetaData] = useState<{
    readonly streamQuality: number;
    readonly networkHealth: number;
    readonly audioStats: {
      readonly rms: number;
      readonly peak: number;
    };
  }>(INITIAL_META_DATA_STATE);

  const isConnecting = stateStatus === 'CONNECTING';
  const isConnected = stateStatus === 'CONNECTED';
  const isDisconnected = stateStatus === 'DISCONNECTED';

  useEffect(() => {
    const subscription = AppState.addEventListener('change', nextAppState => {
      if (nextAppState === 'background') {
        cameraViewRef.current?.stop();
      }
    });

    return () => {
      subscription.remove();
    };
  }, []);

  useEffect(() => {
    if (readyStatus === NotReady) {
      Alert.alert(
        'Sorry, something went wrong :(',
        'Broadcast session is not ready. Please try again.'
      );
    }
  }, [readyStatus]);

  const onIsBroadcastReadyHandler = useCallback(
    (isReady: boolean) =>
      setState(currentState => ({
        ...currentState,
        readyStatus: isReady ? Ready : NotReady,
      })),
    []
  );

  const onBroadcastStateChangedHandler = useCallback(
    (status: StateStatusUnion) =>
      setState(currentState => ({
        ...currentState,
        stateStatus: status,
      })),
    []
  );

  const onBroadcastAudioStatsHandler = useCallback(
    (stats: IAudioStats) =>
      setMetaData(currentState => ({
        ...currentState,
        audioStats: {
          ...currentState.audioStats,
          ...stats,
        },
      })),
    []
  );
  const onBroadcastQualityChangedHandler = useCallback(
    (quality: number) =>
      setMetaData(currentState => ({
        ...currentState,
        streamQuality: quality,
      })),
    []
  );
  const onNetworkHealthChangedHandler = useCallback(
    (health: number) =>
      setMetaData(currentState => ({
        ...currentState,
        networkHealth: health,
      })),
    []
  );

  const onBroadcastErrorHandler = useCallback(
    (exception: IBroadcastSessionError) =>
      console.log('Broadcast session error: ', exception),
    []
  );

  const onErrorHandler = useCallback(
    (errorMessage: string) =>
      console.log('Internal module error: ', errorMessage),
    []
  );

  const onMediaServicesWereLostHandler = useCallback(
    () => console.log('The media server is terminated.'),
    []
  );

  const onMediaServicesWereResetHandler = useCallback(
    () => console.log('The media server is restarted.'),
    []
  );

  const onPressPlayButtonHandler = useCallback(
    () => cameraViewRef.current?.start(),
    []
  );

  const onPressStopButtonHandler = useCallback(
    () => cameraViewRef.current?.stop(),
    []
  );

  const onPressSwapCameraButtonHandler = useCallback(
    () => cameraViewRef.current?.swapCamera(),
    []
  );

  const isStartButtonVisible =
    isDisconnected || stateStatus === INITIAL_BROADCAST_STATE_STATUS;

  return (
    <>
      <IVSBroadcastCameraView
        ref={cameraViewRef}
        style={s.cameraView}
        rtmpsUrl={rtmpsUrl}
        streamKey={streamKey}
        videoConfig={VIDEO_CONFIG}
        audioConfig={AUDIO_CONFIG}
        onError={onErrorHandler}
        onBroadcastError={onBroadcastErrorHandler}
        onIsBroadcastReady={onIsBroadcastReadyHandler}
        onBroadcastAudioStats={onBroadcastAudioStatsHandler}
        onNetworkHealthChanged={onNetworkHealthChangedHandler}
        onBroadcastStateChanged={onBroadcastStateChangedHandler}
        onBroadcastQualityChanged={onBroadcastQualityChangedHandler}
        onMediaServicesWereLost={onMediaServicesWereLostHandler}
        onMediaServicesWereReset={onMediaServicesWereResetHandler}
        {...(__DEV__ && {
          logLevel: 'debug',
          sessionLogLevel: 'debug',
        })}
      />
      <Modal
        visible
        transparent
        animationType="fade"
        supportedOrientations={['landscape']}
      >
        <SafeAreaProvider>
          {readyStatus === None ? (
            <Spinner />
          ) : (
            readyStatus === Ready && (
              <SafeAreaView style={s.primaryContainer}>
                <View style={s.topContainer}>
                  <View style={s.topButtonContainer}>
                    <Button
                      title="Swap"
                      onPress={onPressSwapCameraButtonHandler}
                    />
                    {isConnected && (
                      <Button title="Stop" onPress={onPressStopButtonHandler} />
                    )}
                  </View>
                </View>
                {(isStartButtonVisible || isConnecting) && (
                  <View style={s.middleContainer}>
                    {isStartButtonVisible && (
                      <Button
                        title="Start"
                        onPress={onPressPlayButtonHandler}
                      />
                    )}
                    {isConnecting && <Spinner />}
                  </View>
                )}
                <View style={s.bottomContainer}>
                  <View style={s.metaDataContainer}>
                    <Text
                      style={s.metaDataText}
                    >{`Peak ${audioStats.peak?.toFixed(
                      2
                    )}, Rms: ${audioStats.rms?.toFixed(2)}`}</Text>
                    <Text
                      style={s.metaDataText}
                    >{`Stream quality: ${streamQuality}`}</Text>
                    <Text
                      style={s.metaDataText}
                    >{`Network health: ${networkHealth}`}</Text>
                  </View>
                  {isConnected && <Text style={s.liveText}>LIVE</Text>}
                </View>
              </SafeAreaView>
            )
          )}
        </SafeAreaProvider>
      </Modal>
    </>
  );
};

const s = StyleSheet.create({
  spinner: {
    flex: 1,
  },
  topContainer: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'center',
  },
  topButtonContainer: {
    flexDirection: 'row',
  },
  middleContainer: {
    flex: 1,
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'center',
  },
  bottomContainer: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'flex-end',
    alignItems: 'flex-end',
  },
  button: {
    marginHorizontal: 8,
  },
  buttonText: {
    padding: 8,
    borderRadius: 8,
    fontSize: 20,
    color: '#ffffff',
    backgroundColor: 'rgba(128, 128, 128, 0.4)',
  },
  metaDataContainer: {
    flex: 1,
  },
  metaDataText: {
    color: '#ffffff',
  },
  liveText: {
    color: '#ffffff',
    padding: 8,
    backgroundColor: '#FF5C5C',
    borderRadius: 8,
  },
  cameraView: {
    flex: 1,
    backgroundColor: '#000000',
  },
  primaryContainer: {
    flex: 1,
    padding: 16,
    justifyContent: 'space-between',
  },
});

export default App;
