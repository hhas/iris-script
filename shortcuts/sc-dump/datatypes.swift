//
//  datatypes.swift
//  sclib
//
//  maps known workflow datatypes to their iris equivalents (type names not mapped here are camel_cased and otherwise treated as unknown)

import Foundation

// what about "WFTextTokenString" (interpolated string)
/*
    <key>WFWorkflowActionIdentifier</key>
    <string>is.workflow.actions.showresult</string>
    <key>WFWorkflowActionParameters</key>
    <dict>
        <key>Text</key>
        <dict>
            <key>WFSerializationType</key>
            <string>WFTextTokenString</string>
            <key>Value</key>
            <dict>
                <key>attachmentsByRange</key>
                <dict>
                    <key>{9, 1}</key>
                    <dict>
                        <key>OutputUUID</key>
                        <string>374a8808-eace-4dbf-92fb-826b757d48a1</string>
                        <key>Type</key>
                        <string>ActionOutput</string>
                    </dict>
                </dict>
                <key>string</key>
                <string>Total is ￼!</string>
            </dict>
        </dict>
    </dict>
 
<key>is.workflow.actions.showresult</key>
<dict>
     <key>ActionClass</key>
     <string>WFShowResultAction</string>
     <key>ActionKeywords</key>
     <array>
         <string>text</string>
         <string>such text</string>
         <string>very speech</string>
         <string>much words</string>
         <string>so wow</string>
         <string>string</string>
         <string>display</string>
     </array>
     <key>Category</key>
     <string>Scripting</string>
     <key>Description</key>
     <dict>
         <key>DescriptionSummary</key>
         <string>Shows the specified text in Siri or in an alert.</string>
     </dict>
     <key>IconName</key>
     <string>Scripting</string>
     <key>Input</key>
     <dict>
         <key>Multiple</key>
         <true/>
         <key>ParameterKey</key>
         <string>Text</string>
         <key>Required</key>
         <true/>
         <key>Types</key>
         <array>
             <string>WFStringContentItem</string>
         </array>
     </dict>
     <key>InputPassthrough</key>
     <true/>
     <key>Name</key>
     <string>Show Result</string>
     <key>ParameterSummary</key>
     <string>Show ${Text}</string>
     <key>Parameters</key>
     <array>
         <dict>
             <key>Class</key>
             <string>WFTextInputParameter</string>
             <key>DefaultValue</key>
             <string></string>
             <key>Key</key>
             <string>Text</string>
             <key>Multiline</key>
             <true/>
             <key>Placeholder</key>
             <string>Result</string>
         </dict>
     </array>
     <key>RequiredResources</key>
     <array>
         <string>WFMainThreadResource</string>
     </array>
     <key>Subcategory</key>
     <string>Notification</string>
</dict>
 */


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
    
    // manually map MIME types
    "com.adobe.pdf": "PDF",
    "com.apple.m4a-audio": "M4A_audio",
    "com.apple.quicktime-movie": "QuickTime_movie",
    "com.compuserve.gif": "gif_image",
    "public.data": "data",
    "public.html": "HTML",
    "public.mpeg-4": "MPEG_4",
]
