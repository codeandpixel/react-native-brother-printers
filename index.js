// main index.js

import { NativeModules, NativeEventEmitter } from "react-native";

const { ReactNativeBrotherPrinters } = NativeModules || {};

export const LabelSizeDieCutW17H54 = 0;
export const LabelSizeDieCutW17H87 = 1;
export const LabelSizeDieCutW23H23 = 2;
export const LabelSizeDieCutW29H42 = 3;
export const LabelSizeDieCutW29H90 = 4;
export const LabelSizeDieCutW38H90 = 5;
export const LabelSizeDieCutW39H48 = 6;
export const LabelSizeDieCutW52H29 = 7;
export const LabelSizeDieCutW62H29 = 8;
export const LabelSizeDieCutW62H60 = 9;
export const LabelSizeDieCutW62H75 = 10;
export const LabelSizeDieCutW62H100 = 11;
export const LabelSizeDieCutW60H86 = 12;
export const LabelSizeDieCutW54H29 = 13;
export const LabelSizeDieCutW102H51 = 14;
export const LabelSizeDieCutW102H152 = 15;
export const LabelSizeDieCutW103H164 = 16;
export const LabelSizeRollW12 = 17;
export const LabelSizeRollW29 = 18;
export const LabelSizeRollW38 = 19;
export const LabelSizeRollW50 = 20;
export const LabelSizeRollW54 = 21;
export const LabelSizeRollW62 = 22;
export const LabelSizeRollW62RB = 23;
export const LabelSizeRollW102 = 24;
export const LabelSizeRollW103 = 25;
export const LabelSizeDTRollW90 = 26;
export const LabelSizeDTRollW102 = 27;
export const LabelSizeDTRollW102H51 = 28;
export const LabelSizeDTRollW102H152 = 29;
export const LabelSizeRoundW12DIA = 30;
export const LabelSizeRoundW24DIA = 31;
export const LabelSizeRoundW58DIA = 32;

export const LabelSize = {
  LabelSizeDieCutW17H54,
  LabelSizeDieCutW17H87,
  LabelSizeDieCutW23H23,
  LabelSizeDieCutW29H42,
  LabelSizeDieCutW29H90,
  LabelSizeDieCutW38H90,
  LabelSizeDieCutW39H48,
  LabelSizeDieCutW52H29,
  LabelSizeDieCutW62H29,
  LabelSizeDieCutW62H60,
  LabelSizeDieCutW62H75,
  LabelSizeDieCutW62H100,
  LabelSizeDieCutW60H86,
  LabelSizeDieCutW54H29,
  LabelSizeDieCutW102H51,
  LabelSizeDieCutW102H152,
  LabelSizeDieCutW103H164,
  LabelSizeRollW12,
  LabelSizeRollW29,
  LabelSizeRollW38,
  LabelSizeRollW50,
  LabelSizeRollW54,
  LabelSizeRollW62,
  LabelSizeRollW62RB,
  LabelSizeRollW102,
  LabelSizeRollW103,
  LabelSizeDTRollW90,
  LabelSizeDTRollW102,
  LabelSizeDTRollW102H51,
  LabelSizeDTRollW102H152,
  LabelSizeRoundW12DIA,
  LabelSizeRoundW24DIA,
  LabelSizeRoundW58DIA
}

export const LabelNames = [
  "Die Cut 17mm x 54mm", // 0
  "Die Cut 17mm x 87mm", // 1
  "Die Cut 23mm x 23mm", // 2
  "Die Cut 29mm x 42mm", // 3
  "Die Cut 29mm x 90mm", // 4
  "Die Cut 38mm x 90mm", // 5
  "Die Cut 39mm x 48mm", // 6
  "Die Cut 52mm x 29mm", // 7
  "Die Cut 62mm x 29mm", // 8
  "Die Cut 62mm x 60mm", // 9
  "Die Cut 62mm x 75mm", // 10
  "Die Cut 62mm x 100mm", // 11
  "Die Cut 60mm x 86mm", // 12
  "Die Cut 54mm x 29mm", // 13
  "Die Cut 102mm x 51mm", // 14
  "Die Cut 102mm x 152mm", // 15
  "Die Cut 103mm x 164mm", // 16
  "12mm", // 17
  "29mm", // 18
  "38mm", // 19
  "50mm", // 20
  "54mm", // 21
  "62mm", // 22
  "62mm RB", // 23
  "102mm", // 24
  "103mm", // 25
  "DT 90mm", // 26
  "DT 102mm", // 27
  "DT 102mm x 51mm", // 28
  "DT 102mm x 152mm", // 29
  "Round 12mm", // 30
  "Round 24mm", // 31
  "Round 58mm", // 32
];

/**
 * Starts the discovery process for brother printers
 *
 * @param params
 * @param params.V6             If we should searching using IP v6.
 * @param params.printerName    If we should name the printer something specific.
 *
 * @return {Promise<void>}
 */
export async function discoverPrinters(params = {}) {
  return ReactNativeBrotherPrinters?.discoverPrinters(params);
}

/**
 * Discovers bluetooth printers
 * @returns {Promise<*>}
 */
export async function discoverBluetoothPrinters() {
    return ReactNativeBrotherPrinters?.discoverBluetoothPrinters();
}

/**
 * Checks if a reader is discoverable
 *
 * @param ip
 *
 * @return {Promise<void>}
 */
export async function pingPrinter(ip) {
  return ReactNativeBrotherPrinters?.pingPrinter(ip);
}

/**
 * Prints an image
 *
 * @param device                  Device object
 * @param uri                     URI of image wanting to be printed
 * @param params
 * @param params.autoCut            Boolean if the printer should auto cut the receipt/label
 * @param params.labelSize          Label size that we are printing with
 * @param params.isHighQuality
 * @param params.isHalftoneErrorDiffusion
 *
 * @return {Promise<*>}
 */
export async function printImage(device, uri, params = {}) {
  if (!params.labelSize) {
    return new Error("Label size must be given when printing a label");
  }

  return ReactNativeBrotherPrinters?.printImage(device, uri, params);
}


/**
 * Prints a PDF
 * @param device                  Device object
 * @param uri                     URI of image wanting to be printed
 * @param params
 * @param params.autoCut            Boolean if the printer should auto cut the receipt/label
 * @param params.labelSize          Int Label size that we are printing with
 * @param params.printOrientation   One of [Portrait/Landscape] Print orientation
 *
 * @return {Promise<*>}
 */
export async function printPdf(device, uri, params = {}) {
  if(!params.labelSize) {
    return new Error('Label size must be given when printing a label to PDF');
  }
  return ReactNativeBrotherPrinters?.printPdf(device, uri, params);
}

let listeners;
if (ReactNativeBrotherPrinters) {
  listeners = new NativeEventEmitter(ReactNativeBrotherPrinters);
}

export function registerBrotherListener(key, method) {
  return listeners?.addListener(key, method);
}

export function getPrinterStatus(device) {
  return ReactNativeBrotherPrinters?.getPrinterStatus(device);
}
