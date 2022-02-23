import React, { FC, useState, useEffect } from 'react';
import { PermissionsAndroid } from 'react-native';

import App from './App';

const requestPermissions = async () => {
  await PermissionsAndroid.requestMultiple([
    PermissionsAndroid.PERMISSIONS.CAMERA,
    PermissionsAndroid.PERMISSIONS.RECORD_AUDIO,
  ]);
};

const EntryApp: FC = () => {
  const [isReadyToDisplay, setIsReadyToDisplay] = useState(false);

  useEffect(() => {
    (async () => {
      try {
        await requestPermissions();
      } finally {
        setIsReadyToDisplay(true);
      }
    })();
  }, []);

  return isReadyToDisplay ? <App /> : null;
};

export default EntryApp;
