//
//  datatypes.swift
//  sclib
//
//  maps known workflow datatypes to their iris equivalents

import Foundation

// TO DO: what about extracting type names from WFActions.plist?

let stdTypes = [
    // params
    "WFSwitchParameter": "boolean",
    "WFTextInputParameter": "string",
    "WFDateFieldParameter": "date",
    "WFDatePickerParameter": "date",
    "WFURLParameter": "URL",
    "WFVariableFieldParameter": "identifier",
    "WFVariablePickerParameter": "identifier",
    "WFDynamicEnumerationParameter": "dynamic_choice",
    "WFContentArrayParameter": "ordered_list",
    "WFDictionaryParameter": "keyed_list",
    // "WFTimeIntervalParameter",
    // "WFUnitQuantityFieldParameter",
    // "WFUnitTypePickerParameter",
    // input/output
    "WFContentItem": "item",
    "WFBooleanContentItem": "boolean",
    "WFNumberContentItem": "number",
    "WFStringContentItem": "string",
    "WFDateContentItem": "date",
    "WFArrayContentItem": "ordered_list",
    "WFDictionaryContentItem": "keyed_list",
    // "WFTimeIntervalContentItem",
    // "WFEmailAddressContentItem",
    // "WFFileSizeContentItem",
    // "WFGenericFileContentItem",
    // "WFRichTextContentItem",
    // "WFURLContentItem",
    // "WFWorkflowPickerParameter",
    // "WFWorkflowReference",
    
    
    "NSDate": "date",
    "NSDictionary": "keyed_list",
    //"NSMeasurement", // TO DO: unit types
    "NSNumber": "number",
    "NSString": "string",
    "NSURL": "URL",
    
    "PHAsset": "photo",
    
    "com.adobe.pdf": "PDF",
    "com.apple.m4a-audio": "M4A_audio",
    "com.apple.quicktime-movie": "QuickTime_movie",
    "com.compuserve.gif": "gif_image",
    "public.data": "data",
    "public.html": "HTML",
    "public.mpeg-4": "MPEG_4",
]
