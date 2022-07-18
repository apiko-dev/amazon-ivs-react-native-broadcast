import { Platform } from 'react-native';

import type { Command } from '../IVSBroadcastCameraView.types';
import { getCommandIdByPlatform } from '../IVSBroadcastCameraView';

const STOP_COMMAND = 'STOP';

jest.mock('react-native', () => {
  const ReactNative = jest.requireActual('react-native');

  ReactNative.UIManager.getViewManagerConfig = () => {
    return {
      Commands: {
        [STOP_COMMAND]: 1,
      },
    };
  };

  return ReactNative;
});

jest.mock('react-native/Libraries/Utilities/Platform', () => ({
  OS: 'ios',
}));

describe('getCommandIdByPlatform function works as expected', () => {
  it('iOS platform', () => {
    expect(getCommandIdByPlatform(STOP_COMMAND as Command)).toBe(1);
  });

  it('Android platform', () => {
    Platform.OS = 'android';
    expect(getCommandIdByPlatform(STOP_COMMAND as Command)).toBe(STOP_COMMAND);
  });
});
