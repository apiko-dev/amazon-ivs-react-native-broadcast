# Amazon IVS React Native Broadcast Example App

This repository contains example app which use the Amazon IVS iOS and Android broadcast SDKs via React Native wrapper.

## Setting up and running application

1. Add `rtmpsUrl` and `streamKey` values to [`./app.json`](app.json) file 

2. Install modules
```sh
$ yarn
$ cd ios && pod install && cd ..
```

3. Start `Metro Bundler`
```sh
$ yarn start
```

4. Run the example app on Android platform
```sh
$ yarn android
```

or on iOS platform
```sh
$ yarn ios
```
