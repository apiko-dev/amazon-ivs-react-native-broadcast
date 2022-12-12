import React, { createRef } from 'react';
import { Platform, UIManager } from 'react-native';
import {
  render,
  screen,
  fireEvent,
  cleanup,
} from '@testing-library/react-native';

import type {
  IEventHandlers,
  INativeEventHandlers,
  ExtractComponentProps,
  IIVSBroadcastCameraView,
} from '../IVSBroadcastCameraView.types';
import { Command } from '../IVSBroadcastCameraView.types';
import IVSBroadcastCameraView, {
  NATIVE_VIEW_NAME,
  getCommandIdByPlatform,
} from '../IVSBroadcastCameraView';

type IVSBroadcastCameraViewPartialProps = Partial<
  ExtractComponentProps<typeof IVSBroadcastCameraView>
>;

const { Start, Stop, SwapCamera } = Command;

function nativeSyntheticEventFactory<TName extends keyof INativeEventHandlers>(
  nativeEvent?: Parameters<
    NonNullable<INativeEventHandlers[TName]>
  >[number]['nativeEvent']
) {
  return {
    nativeSyntheticEvent: {
      nativeEvent,
    },
  };
}

const renderIVSBroadcastCameraView = (
  props: IVSBroadcastCameraViewPartialProps = {}
) => render(<IVSBroadcastCameraView rtmpsUrl="" streamKey="" {...props} />);

const getIVSBroadcastCameraView = async (
  props: IVSBroadcastCameraViewPartialProps = {}
) => {
  renderIVSBroadcastCameraView(props);
  return screen.findByTestId(NATIVE_VIEW_NAME);
};

async function testEventHandler<TName extends keyof IEventHandlers>(
  eventHandlerName: TName,
  nativeSyntheticEvent: Partial<
    Parameters<NonNullable<INativeEventHandlers[TName]>>[number]
  >,
  nativeEvent?: Parameters<NonNullable<IEventHandlers[TName]>>[number][]
) {
  const mockEventHandler = jest.fn();
  const ivsBroadcastCameraViewInstance = await getIVSBroadcastCameraView({
    [eventHandlerName]: mockEventHandler,
  });

  fireEvent(
    ivsBroadcastCameraViewInstance,
    eventHandlerName,
    nativeSyntheticEvent
  );
  nativeEvent
    ? expect(mockEventHandler).toHaveBeenCalledWith(...nativeEvent)
    : expect(mockEventHandler).toHaveBeenCalled();
}

afterEach(() => {
  cleanup();
});

jest.mock('react-native', () => {
  const ReactNative = jest.requireActual('react-native');

  ReactNative.Platform.OS = 'ios';
  ReactNative.UIManager.getViewManagerConfig = () => {
    return {
      Commands: {
        START: 0,
      },
    };
  };

  return ReactNative;
});

describe('getCommandIdByPlatform function should return correct command identifier', () => {
  it('iOS platform', () => {
    expect(getCommandIdByPlatform(Start)).toBe(0);
  });

  it('Android platform', () => {
    Platform.OS = 'android';
    expect(getCommandIdByPlatform(Start)).toBe(Start);
  });
});

describe('IVSBroadcastCameraView component', () => {
  test('Defined', async () => {
    const broadcastCameraView = await getIVSBroadcastCameraView();
    expect(broadcastCameraView).toBeDefined();
  });

  test('Snapshot matched', () => {
    const ivsBroadcastCameraViewTree = renderIVSBroadcastCameraView().toJSON();
    expect(ivsBroadcastCameraViewTree).toMatchSnapshot();
  });
});

describe('Event handlers should be called with the correct payload', () => {
  test.each([
    {
      eventHandlerName: 'onError' as const,
      ...nativeSyntheticEventFactory<'onError'>({ message: 'error message' }),
    },
    {
      eventHandlerName: 'onIsBroadcastReady' as const,
      ...nativeSyntheticEventFactory<'onIsBroadcastReady'>({ isReady: true }),
    },
    {
      eventHandlerName: 'onBroadcastAudioStats' as const,
      ...nativeSyntheticEventFactory<'onBroadcastAudioStats'>({
        audioStats: {
          peak: 100,
          rms: 100,
        },
      }),
    },
    {
      eventHandlerName: 'onBroadcastQualityChanged' as const,
      ...nativeSyntheticEventFactory<'onBroadcastQualityChanged'>({
        quality: 1,
      }),
    },
    {
      eventHandlerName: 'onNetworkHealthChanged' as const,
      ...nativeSyntheticEventFactory<'onNetworkHealthChanged'>({
        networkHealth: 1,
      }),
    },
    {
      eventHandlerName: 'onAudioSessionInterrupted' as const,
      ...nativeSyntheticEventFactory<'onAudioSessionInterrupted'>(),
    },
    {
      eventHandlerName: 'onAudioSessionResumed' as const,
      ...nativeSyntheticEventFactory<'onAudioSessionResumed'>(),
    },
    {
      eventHandlerName: 'onMediaServicesWereLost' as const,
      ...nativeSyntheticEventFactory<'onMediaServicesWereLost'>(),
    },
    {
      eventHandlerName: 'onMediaServicesWereReset' as const,
      ...nativeSyntheticEventFactory<'onMediaServicesWereReset'>(),
    },
  ])(
    '$eventHandlerName',
    async ({ eventHandlerName, nativeSyntheticEvent }) => {
      const { nativeEvent } = nativeSyntheticEvent;

      await testEventHandler(
        eventHandlerName,
        nativeSyntheticEvent,
        nativeEvent ? Object.values(nativeEvent) : undefined
      );
    }
  );

  describe('onTransmissionStatisticsChanged event handler should be called with the correct payload', () => {
    const restStatistics = {
      rtt: 22,
      measuredBitrate: 333,
      recommendedBitrate: 444,
    };

    test('Android platform', async () => {
      await testEventHandler(
        'onTransmissionStatisticsChanged',
        {
          nativeEvent: {
            statistics: {
              ...restStatistics,
              networkHealth: 0,
              broadcastQuality: 0,
            },
          },
        },
        [
          {
            ...restStatistics,
            networkHealth: 'EXCELLENT',
            broadcastQuality: 'NEAR_MAXIMUM',
          },
        ]
      );
    });

    test('iOS platform', async () => {
      const networkHealth = 'HIGH';
      const broadcastQuality = 'HIGH';

      await testEventHandler(
        'onTransmissionStatisticsChanged',
        {
          nativeEvent: {
            statistics: {
              ...restStatistics,
              networkHealth,
              broadcastQuality,
            },
          },
        },
        [
          {
            ...restStatistics,
            networkHealth,
            broadcastQuality,
          },
        ]
      );
    });
  });

  describe('onBroadcastStateChanged event handler should be called with the correct payload', () => {
    const metadata = { sessionId: 'sessionId' };

    test('Android platform', async () => {
      await testEventHandler(
        'onBroadcastStateChanged',
        {
          nativeEvent: {
            metadata,
            stateStatus: 1,
          },
        },
        ['DISCONNECTED', metadata]
      );
    });

    test('iOS platform', async () => {
      const stateStatus = 'CONNECTED';

      await testEventHandler(
        'onBroadcastStateChanged',
        {
          nativeEvent: {
            metadata,
            stateStatus,
          },
        },
        [stateStatus, metadata]
      );
    });
  });

  test('onBroadcastError', async () => {
    const errorCode = 1;
    const resetErrorPayload = {
      type: 'type',
      isFatal: true,
      detail: 'detail',
      source: 'source',
      sessionId: 'sessionId',
    };

    await testEventHandler(
      'onBroadcastError',
      {
        nativeEvent: {
          exception: {
            code: errorCode,
            ...resetErrorPayload,
          },
        },
      },
      [
        {
          code: String(errorCode),
          ...resetErrorPayload,
        },
      ]
    );
  });
});

describe('Static methods should be called with the correct command names', () => {
  const mockCommandFn = jest.fn();
  UIManager.dispatchViewManagerCommand = mockCommandFn;

  const ivsBroadcastCameraViewRef = createRef<IIVSBroadcastCameraView>();

  beforeAll(() => {
    Platform.OS = 'android';
  });
  beforeEach(() => {
    mockCommandFn.mockClear();
  });

  test.each([
    { methodName: 'start' as const, commandName: Start },
    { methodName: 'stop' as const, commandName: Stop },
    /**
     * @deprecated in favor of 'cameraPosition' prop.
     */
    { methodName: 'swapCamera' as const, commandName: SwapCamera },
  ])('$methodName', ({ methodName, commandName }) => {
    renderIVSBroadcastCameraView({ ref: ivsBroadcastCameraViewRef });

    ivsBroadcastCameraViewRef.current?.[methodName]();

    expect(mockCommandFn).toHaveBeenCalled();
    const executedCommand = mockCommandFn.mock.calls[0][1];
    expect(executedCommand).toBe(commandName);
  });
});
