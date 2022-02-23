import React, { FC, useEffect, useState, useRef, useCallback } from 'react';
import {
  Text,
  Modal,
  View,
  Alert,
  Button,
  StyleSheet,
  ActivityIndicator,
} from 'react-native';
// import { useAppState } from '@react-native-community/hooks';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';

import { rtmpsUrl, streamKey } from '../app.json';
import {
  CameraView,
  ICameraView,
  StateStatusUnion,
} from 'amazon-ivs-react-native-broadcast';

enum SessionReadyStatus {
  None = 'NONE',
  Ready = 'READY',
  NotReady = 'NOT_READY',
}

const { None, NotReady, Ready } = SessionReadyStatus;

const INITIAL_BROADCAST_STATE_STATUS = 'INVALID' as const;
const DEFAULT_STATE = {
  readyStatus: None,
  stateStatus: INITIAL_BROADCAST_STATE_STATUS,
};
const VIDEO_CONFIG = {
  width: 1920,
  height: 1080,
  bitrate: 8500000,
  targetFrameRate: 60,
  keyframeInterval: 2,
  isBFrames: true,
  isAutoBitrate: true,
  maxBitrate: 8500000,
  minBitrate: 1500000,
};
const AUDIO_CONFIG = {
  bitrate: 128000,
  audioSessionStrategy: 'recordOnly' as const,
};

const Spinner = <ActivityIndicator size="large" />;

const App: FC = () => {
  const cameraViewRef = useRef<ICameraView>(null);
  // const appState = useAppState();

  const [{ stateStatus, readyStatus }, setState] = useState<{
    stateStatus: StateStatusUnion;
    readyStatus: SessionReadyStatus;
  }>(DEFAULT_STATE);

  const isConnecting = stateStatus === 'CONNECTING';
  const isConnected = stateStatus === 'CONNECTED';
  const isDisconnected = stateStatus === 'DISCONNECTED';

  //   useEffect(() => {
  //     if (appState === 'background') {
  //       cameraViewRef.current?.stop();
  //     }
  //   }, [appState]);

  useEffect(() => {
    if (readyStatus === NotReady) {
      Alert.alert(
        'Sorry, something went wrong :(',
        'Broadcast session is not ready. Please try again.'
      );
    }
  }, [readyStatus]);

  const onIsBroadcastReadyHandler = useCallback(
    isReady =>
      setState(currentState => ({
        ...currentState,
        readyStatus: isReady ? Ready : NotReady,
      })),
    []
  );

  const onBroadcastStateChangedHandler = useCallback(status => {
    console.log('next status: ', status);
    setState(currentState => ({
      ...currentState,
      stateStatus: status,
    }));
  }, []);

  const onBroadcastErrorHandler = useCallback(
    exception => console.log('Broadcast session error: ', exception),
    []
  );

  const onErrorHandler = useCallback(
    errorMessage => console.log('Internal error: ', errorMessage),
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

  const isPlayButtonVisible =
    isDisconnected || stateStatus === INITIAL_BROADCAST_STATE_STATUS;

  return (
    <>
      <CameraView
        ref={cameraViewRef}
        style={s.cameraView}
        rtmpsUrl={rtmpsUrl}
        streamKey={streamKey}
        videoConfig={VIDEO_CONFIG}
        audioConfig={AUDIO_CONFIG}
        onIsBroadcastReady={onIsBroadcastReadyHandler}
        onBroadcastStateChanged={onBroadcastStateChangedHandler}
        onError={onErrorHandler}
        onBroadcastError={onBroadcastErrorHandler}
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
          {readyStatus === None
            ? Spinner
            : readyStatus === Ready && (
                <SafeAreaView style={s.primaryContainer}>
                  <View style={s.topContainer}>
                    <View style={s.topButtonContainer}>
                      <Button
                        title="Swap"
                        onPress={onPressSwapCameraButtonHandler}
                      />
                      {isConnected && (
                        <Button
                          title="Stop"
                          onPress={onPressStopButtonHandler}
                        />
                      )}
                    </View>
                  </View>
                  {(isPlayButtonVisible || isConnecting) && (
                    <View style={s.middleContainer}>
                      {isPlayButtonVisible && (
                        <Button
                          title="Start"
                          onPress={onPressPlayButtonHandler}
                        />
                      )}
                      {isConnecting && Spinner}
                    </View>
                  )}
                  <View style={s.bottomContainer}>
                    {isConnected && <Text style={s.liveText}>Live</Text>}
                  </View>
                </SafeAreaView>
              )}
        </SafeAreaProvider>
      </Modal>
    </>
  );
};

const s = StyleSheet.create({
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
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  bottomContainer: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'flex-end',
    alignItems: 'flex-end',
  },
  liveText: {
    color: '#FF5C5C',
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
