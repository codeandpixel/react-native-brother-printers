# react-native-brother-printers

React Native Brother Printers is a react-native module that will allow you to interact with the brother printers with iOS. 

This package has been forked from the original [react-native-brother-printers](https://github.com/Avery246813579/react-native-brother-printers) package, has been updated to work with the latest version of react-native, the latest version of the brother sdk, and expo.

We've also added a few extra features, such as the ability to print PDFs, and the ability to discover and use bluetooth printers.

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
import {discoverPrinters, discoverBluetoothPrinters, registerBrotherListener} from 'react-native-brother-printers';

discoverPrinters({
  V6: true,
});

registerBrotherListener("onDiscoverPrinters", (printers) => {
  // Store these printers somewhere
});

discoverBluetoothPrinters({
    V6: true,
});

registerBrotherListener("onDiscoverBluetoothPrinters", (printers) => {
    // Store these printers somewhere
});
```

### Selecting a printer to use
To set a printer in your store using redux, including automatic detection of the badge size labels currently in the printer...

```javascript
const findMatchedLabelSize = (labelSize) => {
// find the matched label size from the brotherLabelSizes array
return _.find(brotherLabelSizes, (item) => item.labelSize === labelSize)
}

const brotherPrinterSelected = (value) => {
    
    // Set your printer to the store...

    // Now we have to use the brother sdk to find out what kind of paper this printer uses
    // and set that as the default
    //  LOG  {"backgroundColor": 0, "height_mm": 0, "inkColor": 7, "isHeightInfinite": true, "labelSize": 23, "mediaType": 3, "model": 27, "width_mm": 62}
    getPrinterStatus(value).then((status) => {
        console.log('brother printer status', status)
        // find the corresponding labelSize from the brotherLabelSizes array
        let matchedLabelSize = findMatchedLabelSize(status.labelSize)
        console.log('matchedLabelSize', matchedLabelSize)
        // if we matched one, set it using setBrotherPrinterLabelSize
        if(matchedLabelSize) {
            // Use the matchedLabelSize to set the printer label size for use in the printImage/printPdf functions
        }
    });
}
```

### Warning: Remember to add the following to your Info.plist file
_Special fun, the UISupportedExternalAccessoryProtocols is required for the app to be able to connect to the printer over bluetooth, and apparently no one decided to document it anywhere_

Also of note, in order to get your app approved by Apple, you must have approval to use the protocol: com.brother.ptcbp (if you're using Bluetooth).  The form can be found on the [Brother SDK](https://support.brother.com/g/s/es/dev/en/mobilesdk/download/index.html?c=eu_ot&lang=en&navi=offall&comple=on&redirect=on#iphone) page.  Look for the link for "iOS App Approval Process" and fill out the form.

If you're NOT using bluetooth, you should remove the UISupportedExternalAccessoryProtocols from the info.plist file or Apple will require Brother approval anyway.

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>$(PRODUCT_NAME) uses Bluetooth to discover and connect to printers</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>$(PRODUCT_NAME) uses Bluetooth to discover and connect to printers</string> 
<key>UISupportedExternalAccessoryProtocols</key>
<array>
    <string>com.brother.ptcbp</string>
</array>
```

Or into your eas.json file
```json
{
  "ios": {
    "infoPlist": {
      "NSBluetoothAlwaysUsageDescription": "$(PRODUCT_NAME) uses Bluetooth to discover and connect to printers",
      "NSBluetoothPeripheralUsageDescription": "$(PRODUCT_NAME) uses Bluetooth to discover and connect to printers",
      "UISupportedExternalAccessoryProtocols": ["com.brother.ptcbp"]
    }
  }
}
```

_Special thanks to [Will](https://github.com/wjlafrance) for remembering the magic trick to get this working!_

### Printing an image
To print an image, using the `printImage` function, with the first parameter being the printer found during discover,
the second being the uri of the image you want to print, and the third being an objective that contains the label size.

You can find a list of LabelSize and LabelNames inside the package as well.

```javascript
import {printImage, LabelSize} from 'react-native-brother-printers';

await printImage(
    printer, 
    uri, 
    {
        labelSize: LabelSize.LabelSizeRollW62RB
    }
);
```

### Printing a PDF
To print a PDF, using the `printPdf` function, with the first parameter being the printer found during discover,
the second being the uri of the PDF you want to print, and the third being an objective that contains the label size.

You can find a list of LabelSize and LabelNames inside the package as well.

```javascript
import {printPdf, LabelSize} from 'react-native-brother-printers';
const result = await printPdf(
    selectedPrinter,
    badgeFile,
    {
        labelSize: LabelSize.LabelSizeRollW62RB,
        autoCut: true,
    },
);
```

### Using Base64 to Print to PDF

If you have a base64 string, and you're using react-native, then you're in for a fun treat trying to convert to files that will work reliably across all devices. 

The following works for us, and we hope it works for you too. 

```javascript
const convertBase64toPdf = async (base64String) => {

    if(!base64String) {
        console.log('No base64 string to convert')
        return;
    }

    //Without this the FileSystem crashes with 'bad base-64'
    let base64Data = base64String.replace("data:image/png;base64,","");
    // replace the data:application/pdf;base64 prefix to empty string
    base64Data = base64Data.replace("data:application/pdf;base64,","");

    try {
        // This creates a temp uri file so there's no need to download an image_source to get a URI Path
        const uri = FileSystem.cacheDirectory + 'image-temp-'
            + Math.floor(Math.random() * 1000000)
            + '.pdf'
        await FileSystem.writeAsStringAsync(
            uri,
            base64Data,
            {
                'encoding': FileSystem.EncodingType.Base64,
            }
        )

        console.log('Badge image written to temp file: ' + uri)
        return uri

    } catch (e) {
        console.log('*Error*')
        console.log(e)
    }
}
```

Then you can use as follows:

```javascript
const badgeFile = await convertBase64toPdf(base64String)
const result = await printPdf(
    selectedPrinter,
    badgeFile,
    {
        labelSize: LabelSize.LabelSizeRollW62RB,
        autoCut: true,
    },
);
```

### Useful Links

- [Brother SDK](https://support.brother.com/g/s/es/htmldoc/mobilesdk/)
