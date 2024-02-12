# react-native-brother-printers

React Native Brother Printers is a react-native module that will allow you to interact with the brother printers with iOS. 

## Getting started

`$ npm install @codeandpixel/react-native-brother-printers --save`

or 

`$ yarn add @codeandpixel/react-native-brother-printers`

or if using expo (must be using prebuild, see [https://docs.expo.dev/workflow/prebuild/](https://docs.expo.dev/workflow/prebuild) for more information on prebuilds)

```
npx expo install @codeandpixel/react-native-brother-printers
npx expo prebuild --clean -p ios
npx expo run:ios
```

## Usage

### Discovering a printer
To discover printers use the discoverPrinters function. You can pass in the option parameters `printerName` to change
the printer name, or V6 to enable ipv6 detection. Both parameters can be left blank. 

```javascript
import {discoverPrinters, registerBrotherListener} from 'react-native-brother-printers';

discoverPrinters({
  V6: true,
});

registerBrotherListener("onDiscoverPrinters", (printers) => {
  // Store these printers somewhere
});
```

### Printing an image
To print an image, using the `printImage` function, with the first parameter being the printer found during discover,
the second being the uri of the image you want to print, and the third being an objective that contains the label size.

You can find a list of LabelSize and LabelNames inside the package as well.

```javascript
import {printImage, LabelSize} from 'react-native-brother-printers';

await printImage(printer, uri, {labelSize: LabelSize.LabelSizeRollW62RB});
```

