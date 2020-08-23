//
//  main.swift
//  sclib
//

import Foundation
import iris

// TO DO: need to write types to file, e.g. as `shortcut_type NAME`; not sure how most of these should represent themselves


let args = CommandLine.arguments

if args.count != 3 {
    print("USAGE: sc-dump SRC DEST")
    print(args)
    exit(1)
}

let src = URL(fileURLWithPath: args[1])
let dest = URL(fileURLWithPath: args[2])

extension FileHandle {
    func write(_ string: String) {
        self.write(string.data(using: .utf8)!)
    }
}

print("reading", src)
do {
    guard let data = InputStream(url: src) else {
        throw InternalError(description: "Can’t open \(src)")
    }
    data.open()
    defer { data.close() }
    guard let actions = try PropertyListSerialization.propertyList(with: data, format: nil) as? [String:Dict] else {
        throw InternalError(description: "Can’t read \(src)")
    }
    
    var actionsGlue = try FileHandle(forWritingTo: dest.appendingPathComponent("shortcut actions.iris-glue"))
    defer { actionsGlue.closeFile() }
    actionsGlue.truncateFile(atOffset: 0)
    
    for (id, dict) in actions.sorted(by: {$0.key.lowercased() < $1.key.lowercased()}) {
        if let s = readAction(id: id, action: dict) {
            actionsGlue.write(s)
        }
    }
    var typesGlue = try FileHandle(forWritingTo: dest.appendingPathComponent("shortcut types.iris-glue"))
    defer { typesGlue.closeFile() }
    typesGlue.truncateFile(atOffset: 0)
    writeShortcutTypes(to: typesGlue)
    print("wrote", dest)
} catch {
    print("failed", error)
}


/*
 // Input/Output:
 AVAsset
 CLLocation
 EKEvent
 ENNoteRef
 INNote
 INRideStatus
 MKMapItem
 MPMediaItem
 NSAttributedString
 NSDate
 NSDecimalNumber
 NSDictionary
 NSMeasurement
 NSNumber
 NSString
 NSURL
 PHAsset
 REMReminder
 WFAVAssetContentItem
 WFAppStoreAppContentItem
 WFArticle
 WFArticleContentItem
 WFBooleanContentItem
 WFCalendarEventContentItem
 WFContact
 WFContactContentItem
 WFContentItem
 WFDateContentItem
 WFDictionaryContentItem
 WFEmailAddress
 WFEmailAddressContentItem
 WFFileSizeContentItem
 WFGenericFileContentItem
 WFGiphyObject
 WFHKSampleContentItem
 WFHKWorkoutContentItem
 WFImage
 WFImageContentItem
 WFLocationContentItem
 WFMPMediaContentItem
 WFMachineReadableCode
 WFNoteContentItem
 WFNumberContentItem
 WFPDFContentItem
 WFPhoneNumber
 WFPhoneNumberContentItem
 WFPhotoMediaContentItem
 WFPodcastEpisodeContentItem
 WFPodcastShowContentItem
 WFRichTextContentItem
 WFSafariWebPageContentItem
 WFShazamMedia
 WFStockData
 WFStreetAddress
 WFStringContentItem
 WFTimeIntervalContentItem
 WFTrelloBoard
 WFTrelloBoardContentItem
 WFTrelloCard
 WFTrelloCardContentItem
 WFTrelloList
 WFTrelloListContentItem
 WFTripInfo
 WFURLContentItem
 WFUlyssesSheetContentItem
 WFWeatherData
 WFWorkflowReference
 WFiTunesProductContentItem
 com.apple.m4a-audio
 com.apple.quicktime-movie
 com.compuserve.gif
 public.data
 public.html
 public.mpeg-4

 // Parameter:
 WFAccountPickerParameter
 WFAppPickerParameter
 WFArchiveFormatParameter
 WFArrayParameter
 WFCalendarPickerParameter
 WFConditionalOperatorParameter
 WFConditionalSubjectParameter
 WFContactFieldParameter
 WFContactHandleFieldParameter
 WFContentArrayParameter
 WFCountryFieldParameter
 WFCurrencyQuantityFieldParameter
 WFCustomDateFormatParameter
 WFCustomIntentDynamicEnumerationParameter
 WFDateFieldParameter
 WFDatePickerParameter
 WFDictateTextLanguagePickerParameter
 WFDictionaryParameter
 WFDurationQuantityFieldParameter
 WFDynamicEnumerationParameter
 WFDynamicTagFieldParameter
 WFEmailAddressFieldParameter
 WFEnumerationParameter
 WFEvernoteNotebookPickerParameter
 WFEvernoteTagsTagFieldParameter
 WFExpandingParameter
 WFFaceTimeTypePickerParameter
 WFFileSizePickerParameter
 WFFitnessWorkoutTypePickerParameter
 WFFlipImageDirectionPickerParameter
 WFGetDistanceUnitPickerParameter
 WFHealthActionEndDateFieldParameter
 WFHealthActionStartDateFieldParameter
 WFHealthCategoryAdditionalPickerParameter
 WFHealthCategoryPickerParameter
 WFHealthQuantityAdditionalFieldParameter
 WFHealthQuantityAdditionalPickerParameter
 WFHealthQuantityFieldParameter
 WFHomeAccessoryPickerParameter
 WFHomeCharacteristicPickerParameter
 WFHomeServicePickerParameter
 WFImageConvertFormatPickerParameter
 WFIntentAppPickerParameter
 WFLightroomPresetPickerParameter
 WFLocationParameter
 WFMapsAppPickerParameter
 WFMeasurementUnitPickerParameter
 WFMediaPickerParameter
 WFMediaRoutePickerParameter
 WFNetworkPickerParameter
 WFNoteGroupPickerParameter
 WFNumberFieldParameter
 WFNumericDynamicEnumerationParameter
 WFPaymentMethodParameter
 WFPhoneNumberFieldParameter
 WFPhotoAlbumPickerParameter
 WFPlaylistPickerParameter
 WFPodcastPickerParameter
 WFQuantityTypePickerParameter
 WFRemindersListPickerParameter
 WFRideOptionParameter
 WFSSHKeyParameter
 WFSearchLocalBusinessesRadiusParameter
 WFSlackChannelPickerParameter
 WFSliderParameter
 WFSpeakTextLanguagePickerParameter
 WFSpeakTextRateParameter
 WFSpeakTextVoicePickerParameter
 WFStepperParameter
 WFStorageServicePickerParameter
 WFSwitchParameter
 WFTextInputParameter
 WFTimeIntervalParameter
 WFTodoistProjectPickerParameter
 WFTranslateTextLanguagePickerParameter
 WFTrelloBoardPickerParameter
 WFTrelloListPickerParameter
 WFTumblrBlogPickerParameter
 WFTumblrComposeInAppParameter
 WFURLParameter
 WFUnitQuantityFieldParameter
 WFUnitTypePickerParameter
 WFVariableFieldParameter
 WFVariablePickerParameter
 WFWorkflowPickerParameter
 WFWorkoutGoalQuantityFieldParameter
 WFWorkoutTypePickerParameter
 WFWunderlistListPickerParameter
 WFiTunesStoreCountryPickerParameter

 // Disallowed:
 Ask
 Clipboard
 Variable

 */
