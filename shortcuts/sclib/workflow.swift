//
//  workflow.swift
//  sclib
//

import Foundation
import iris


let workflowName = Symbol(".workflow")


public typealias Dict = [String:Any]


public class Workflow: OpaqueValue<Dict> {
    
    open override var description: String { return self.data.description }

    private var actions = [Dict]()
    
    public convenience init() {
        self.init([
            "WFWorkflowActions": [Dict](),
            "WFWorkflowClientRelease": "2.0",
            "WFWorkflowClientVersion": "700",
            "WFWorkflowImportQuestions": [Any](),
            "WFWorkflowInputContentItemClasses": [
                "WFAppStoreAppContentItem",
                "WFArticleContentItem",
                "WFContactContentItem",
                "WFDateContentItem",
                "WFEmailAddressContentItem",
                "WFGenericFileContentItem",
                "WFImageContentItem",
                "WFiTunesProductContentItem",
                "WFLocationContentItem",
                "WFDCMapsLinkContentItem",
                "WFAVAssetContentItem",
                "WFPDFContentItem",
                "WFPhoneNumberContentItem",
                "WFRichTextContentItem",
                "WFSafariWebPageContentItem",
                "WFStringContentItem",
                "WFURLContentItem",
            ],
            "WFWorkflowIcon": [
                "WFWorkflowIconGlyphNumber": 59727,
                "WFWorkflowIconStartColor": 1239959039,
            ],
            "WFWorkflowMinimumClientVersion": 411,
            "WFWorkflowTypes": [
                "ActionExtension",
            ]
        ])
    }
    
    internal required init(_ data: SwiftType) {
        super.init(data)
    }
    
    func add(action: Dict) {
        self.actions.append(action)
    }
}

