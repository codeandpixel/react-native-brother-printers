// ReactNativeBrotherPrinters.m

#import "ReactNativeBrotherPrinters.h"
#import <React/RCTConvert.h>

@implementation ReactNativeBrotherPrinters

NSString *const DISCOVER_READERS_ERROR = @"DISCOVER_READERS_ERROR";
NSString *const DISCOVER_READER_ERROR = @"DISCOVER_READER_ERROR";
NSString *const PRINT_ERROR = @"PRINT_ERROR";
NSString *const STATUS_ERROR = @"STATUS_ERROR";

RCT_EXPORT_MODULE()

-(void)startObserving {
    hasListeners = YES;
}

-(void)stopObserving {
    hasListeners = NO;
}

- (NSArray<NSString *> *)supportedEvents {
    return @[
        @"onBrotherLog",

        @"onDiscoverPrinters",
    ];
}

RCT_REMAP_METHOD(discoverPrinters, discoverOptions:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Called the function");

        self->_brotherDeviceList = [[NSMutableArray alloc] initWithCapacity:0];

        self->_networkManager = [[BRPtouchNetworkManager alloc] init];
        self->_networkManager.delegate = self;

        NSString *path = [[NSBundle mainBundle] pathForResource:@"PrinterList" ofType:@"plist"];

        if (path) {
            NSDictionary *printerDict = [NSDictionary dictionaryWithContentsOfFile:path];
            NSArray *printerList = [[NSArray alloc] initWithArray:printerDict.allKeys];

            [self->_networkManager setPrinterNames:printerList];
        } else {
            NSLog(@"Could not find PrinterList.plist");
        }

        //    Start printer search
        int response = [self->_networkManager startSearch: 5.0];

        if (response == RET_TRUE) {
            resolve(Nil);
        } else {
            reject(DISCOVER_READERS_ERROR, @"A problem occurred when trying to execute discoverPrinters", Nil);
        }
    });
}

RCT_REMAP_METHOD(pingPrinter, printerAddress:(NSString *)ip resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    BRLMChannel *channel = [[BRLMChannel alloc] initWithWifiIPAddress:ip];

    BRLMPrinterDriverGenerateResult *driverGenerateResult = [BRLMPrinterDriverGenerator openChannel:channel];
    if (driverGenerateResult.error.code != BRLMOpenChannelErrorCodeNoError ||
        driverGenerateResult.driver == nil) {

        NSLog(@"%@", @(driverGenerateResult.error.code));
        NSString *errorCodeString = [NSString stringWithFormat:@"%@", @(driverGenerateResult.error.code)];
        NSError* error = [NSError errorWithDomain:@"com.react-native-brother-printers.rn" code:driverGenerateResult.error.code userInfo:[NSDictionary dictionaryWithObject:errorCodeString forKey:NSLocalizedDescriptionKey]];

        [driverGenerateResult.driver closeChannel];

        return reject(DISCOVER_READER_ERROR, @"A problem occured when trying to execute pingPrinter", error);
    }

    NSLog(@"We were able to discover a printer");
    [driverGenerateResult.driver closeChannel];
    resolve(Nil);
}

RCT_REMAP_METHOD(getPrinterStatus, deviceInfo:(NSDictionary *)device resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Called the getPrinterStatus function");
    BRPtouchDeviceInfo *deviceInfo = [self deserializeDeviceInfo:device];

    BRLMChannel *channel = [[BRLMChannel alloc] initWithWifiIPAddress:deviceInfo.strIPAddress];

    BRLMPrinterDriverGenerateResult *driverGenerateResult = [BRLMPrinterDriverGenerator openChannel:channel];
    if (driverGenerateResult.error.code != BRLMOpenChannelErrorCodeNoError ||
        driverGenerateResult.driver == nil) {
        NSLog(@"%@", @(driverGenerateResult.error.code));
        return;
    }

    BRLMPrinterDriver *printerDriver = driverGenerateResult.driver;
    BRLMGetPrinterStatusResult *status = [printerDriver getPrinterStatus];

    if (status.error.code != BRLMGetStatusErrorCodeNoError) {

        NSLog(@"Error - getPrinterStatus: %@", status.error);

        NSString *errorCodeString = [NSString stringWithFormat:@"Error code: %ld", (long)status.error.code];
        NSString *errorDescription = [NSString stringWithFormat:@"%@ - %@", errorCodeString, status.error.description];

        NSDictionary *userInfo = @{
            NSLocalizedDescriptionKey: errorDescription,
            @"errorCode": @(status.error.code),
        };

        NSError *error = [NSError errorWithDomain:@"com.react-native-brother-printers.rn"
                                            code:status.error.code
                                        userInfo:userInfo];

        [printerDriver closeChannel]; // Close the channel

        reject(STATUS_ERROR, @"There was an error trying to get status", error);



    } else {
        [printerDriver closeChannel];
        resolve([self serializeDeviceStatus: status.status]);
    }
}

RCT_REMAP_METHOD(printImage, deviceInfo:(NSDictionary *)device printerUri: (NSString *)imageStr printImageOptions:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Called the printImage function");
    BRPtouchDeviceInfo *deviceInfo = [self deserializeDeviceInfo:device];

    BRLMChannel *channel = [[BRLMChannel alloc] initWithWifiIPAddress:deviceInfo.strIPAddress];

    BRLMPrinterDriverGenerateResult *driverGenerateResult = [BRLMPrinterDriverGenerator openChannel:channel];
    if (driverGenerateResult.error.code != BRLMOpenChannelErrorCodeNoError ||
        driverGenerateResult.driver == nil) {
        NSLog(@"%@", @(driverGenerateResult.error.code));
        return;
    }

    BRLMPrinterDriver *printerDriver = driverGenerateResult.driver;

    BRLMPrinterModel model = [BRLMPrinterClassifier transferEnumFromString:deviceInfo.strModelName];
    BRLMQLPrintSettings *qlSettings = [[BRLMQLPrintSettings alloc] initDefaultPrintSettingsWithPrinterModel:model];

    qlSettings.autoCut = true;

    if (options[@"autoCut"]) {
        qlSettings.autoCut = [options[@"autoCut"] boolValue];
    }

    if (options[@"labelSize"]) {
        qlSettings.labelSize = [options[@"labelSize"] intValue];
    }

    if (options[@"isHighQuality"]) {
        if ([options[@"isHighQuality"] boolValue]) {
            qlSettings.printQuality = BRLMPrintSettingsPrintQualityBest;
            NSLog(@"High Quality is enabled");
        } else {
            qlSettings.printQuality = BRLMPrintSettingsPrintQualityFast;
            NSLog(@"High Quality is disabled");
        }
    }

    if (options[@"isHalftoneErrorDiffusion"]) {
        if ([options[@"isHalftoneErrorDiffusion"] boolValue]) {
            qlSettings.halftone = BRLMPrintSettingsHalftoneErrorDiffusion;
            NSLog(@"Error Diffusion is enabled");
        } else {
            qlSettings.halftone = BRLMPrintSettingsHalftoneThreshold;
            NSLog(@"Error Diffusion is disabled");
        }
    }

    NSLog(@"Auto Cut: %@, Label Size: %@", options[@"autoCut"], options[@"labelSize"]);

    NSURL *url = [NSURL URLWithString:imageStr];
    BRLMPrintError *printError = [printerDriver printImageWithURL:url settings:qlSettings];

    if (printError.code != BRLMPrintErrorCodeNoError) {
        NSLog(@"Error - Print Image: %@", printError);

        NSString *errorCodeString = [NSString stringWithFormat:@"Error code: %ld", (long)printError.code];
        NSString *errorDescription = [NSString stringWithFormat:@"%@ - %@", errorCodeString, printError.description];

        NSDictionary *userInfo = @{
            NSLocalizedDescriptionKey: errorDescription,
            @"errorCode": @(printError.code),
        };

        NSError *error = [NSError errorWithDomain:@"com.react-native-brother-printers.rn"
                                            code:printError.code
                                        userInfo:userInfo];

        [printerDriver closeChannel]; // Close the channel

        reject(PRINT_ERROR, @"There was an error trying to print the image", error);
    } else {
        NSLog(@"Success - Print Image");

        [printerDriver closeChannel]; // Close the channel

        resolve(Nil);
    }
}

RCT_REMAP_METHOD(printPdf, deviceInfo:(NSDictionary *)device printerUri: (NSString *)pdfStr printPdfOptions:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Called the printPdf function");
    BRPtouchDeviceInfo *deviceInfo = [self deserializeDeviceInfo:device];

    BRLMChannel *channel = [[BRLMChannel alloc] initWithWifiIPAddress:deviceInfo.strIPAddress];

    BRLMPrinterDriverGenerateResult *driverGenerateResult = [BRLMPrinterDriverGenerator openChannel:channel];
    if (driverGenerateResult.error.code != BRLMOpenChannelErrorCodeNoError ||
        driverGenerateResult.driver == nil) {
        NSLog(@"%@", @(driverGenerateResult.error.code));
        return;
    }

    BRLMPrinterDriver *printerDriver = driverGenerateResult.driver;

    BRLMPrinterModel model = [BRLMPrinterClassifier transferEnumFromString:deviceInfo.strModelName];
    BRLMQLPrintSettings *qlSettings = [[BRLMQLPrintSettings alloc] initDefaultPrintSettingsWithPrinterModel:model];

    // Setup the print settings
    if (options[@"labelSize"]) {
        qlSettings.labelSize = [options[@"labelSize"] intValue];
    }

    qlSettings.autoCut = options[@"autoCut"] ? [options[@"autoCut"] boolValue] : YES;
    qlSettings.resolution = BRLMPrintSettingsResolutionHigh;
    if (qlSettings.labelSize == BRLMQLPrintSettingsLabelSizeRollW62RB) {
        qlSettings.biColorRedEnhancement = 10;
    }

    qlSettings.halftone = BRLMPrintSettingsHalftonePatternDither;
    qlSettings.printQuality = BRLMPrintSettingsPrintQualityBest;

    // printOrientation
    if (options[@"printOrientation"]) {
        if ([options[@"printOrientation"] isEqualToString:@"Portrait"]) {
            qlSettings.printOrientation = BRLMPrintSettingsOrientationPortrait;
            NSLog(@"Portrait is enabled");
        } else if([options[@"printOrientation"] isEqualToString:@"Landscape"]) {
            qlSettings.printOrientation = BRLMPrintSettingsOrientationLandscape;
            NSLog(@"Landscape is enabled");
        } else {
            NSLog(@"Automatic orientation is enabled");
        }
    }

    NSURL *url = [NSURL URLWithString:pdfStr];
    BRLMPrintError *printError = [printerDriver printPDFWithURL:url settings:qlSettings];

    if (printError.code != BRLMPrintErrorCodeNoError) {
        NSLog(@"Error - Print Image: %@", printError);

        NSError* error = [NSError errorWithDomain:@"com.react-native-brother-printers.rn" code:1 userInfo:[NSDictionary dictionaryWithObject:printError.description forKey:NSLocalizedDescriptionKey]];

        [printerDriver closeChannel]; // Close the channel
        reject(PRINT_ERROR, @"There was an error trying to print the pdf", error);
    } else {
        NSLog(@"Success - Print pdf");
        [printerDriver closeChannel]; // Close the channel
        resolve(Nil);
    }
}

-(void)didFinishSearch:(id)sender
{
    NSLog(@"didFinishedSearch");

    //  get BRPtouchNetworkInfo Class list
    [_brotherDeviceList removeAllObjects];
    _brotherDeviceList = (NSMutableArray*)[_networkManager getPrinterNetInfo];

    NSLog(@"_brotherDeviceList [%@]",_brotherDeviceList);

    NSMutableArray *_serializedArray = [[NSMutableArray alloc] initWithCapacity:_brotherDeviceList.count];

    for (BRPtouchDeviceInfo *deviceInfo in _brotherDeviceList) {
        [_serializedArray addObject:[self serializeDeviceInfo:deviceInfo]];

        NSLog(@"Model: %@, IP Address: %@", deviceInfo.strModelName, deviceInfo.strIPAddress);

    }

    [self sendEventWithName:@"onDiscoverPrinters" body:_serializedArray];

    return;
}

- (NSDictionary *) serializeDeviceInfo:(BRPtouchDeviceInfo *)device {
    return @{
        @"ipAddress": device.strIPAddress,
        @"location": device.strLocation,
        @"modelName": device.strModelName,
        @"printerName": device.strPrinterName,
        @"serialNumber": device.strSerialNumber,
        @"nodeName": device.strNodeName,
        @"macAddress": device.strMACAddress,
    };
}

- (NSDictionary *) serializeDeviceStatus:(BRLMPrinterStatus *)status {
    BRLMMediaInfo *mediaInfo = status.mediaInfo;
    bool success;
    BRLMQLPrintSettingsLabelSize labelSize = [mediaInfo getQLLabelSize:&success];

    return @{
        @"model": @(status.model),
        @"mediaType": @(status.mediaInfo.mediaType),
        @"backgroundColor": @(status.mediaInfo.backgroundColor),
        @"inkColor": @(status.mediaInfo.inkColor),
        @"width_mm": @(status.mediaInfo.width_mm),
        @"height_mm": @(status.mediaInfo.height_mm),
        @"isHeightInfinite": @(status.mediaInfo.isHeightInfinite),
        @"labelSize": success == YES ? @(labelSize) : Nil,
    };
}

- (BRPtouchDeviceInfo *) deserializeDeviceInfo:(NSDictionary *)device {
    BRPtouchDeviceInfo *deviceInfo = [[BRPtouchDeviceInfo alloc] init];

    deviceInfo.strIPAddress = [RCTConvert NSString:device[@"ipAddress"]];
    deviceInfo.strLocation = [RCTConvert NSString:device[@"location"]];
    deviceInfo.strModelName = [RCTConvert NSString:device[@"modelName"]];
    deviceInfo.strPrinterName = [RCTConvert NSString:device[@"printerName"]];
    deviceInfo.strSerialNumber = [RCTConvert NSString:device[@"serialNumber"]];
    deviceInfo.strNodeName = [RCTConvert NSString:device[@"nodeName"]];
    deviceInfo.strMACAddress = [RCTConvert NSString:device[@"macAddress"]];

    NSLog(@"We got here");

    return deviceInfo;
}

@end
