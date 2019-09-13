//
//  aelib.swift
//

import Foundation
import AppleEvents
import SwiftAutomation


// TO DO: need to decide native representations for date and file so that these can be reliably bridged


// TO DO: cache glue tables for reuse (TO DO: how practical to have a global on-disk cache? this'd need to know each app's bundle ID and version so that it can reload correct terms for target app, and invalidate old entries when a newer version of app is found; caveat some [pro] apps, e.g. Adobe CC/MS Office, may have multiple versions installed)


// TO DO: singular element names also need to be added to elementsByName table, e.g. `document at 1` currently doesn't work (also need elementsByCode Singular/Plural tables for pretty printer to use); either add extra elementsSingular dict to AETE/SDEF parsers or subclass KeywordTerm to hold both singular and plural names for elements



/******************************************************************************/
// target address, terminology tables, codecs


class NativeAppData: AppData {
    
    let glueTable: GlueTable
    private var commandInterfaces = [String: HandlerInterface]()
    
    public required init(applicationURL: URL? = nil, useTerminology: TerminologyType = .sdef) throws {
        let glueTable = GlueTable(keywordConverter: nativeKeywordConverter, allowSingularElements: true)
        // temporary; TO DO: if .aete or URL not available, use getAETE, else if .sdef use SDEF
        if let applicationURL = applicationURL {
            switch useTerminology {
            case .sdef: try glueTable.add(SDEF: applicationURL)
            case .aete: try glueTable.add(AETE: SwiftAutomation.AEApplication(url: applicationURL).getAETE())
            default: () // use built-in terminology only
            }
        }
        self.glueTable = glueTable
        let specifierFormatter = SpecifierFormatter(applicationClassName: "Application",
                                                    classNamePrefix: "",
                                                    typeNames: glueTable.typesByCode,
                                                    propertyNames: glueTable.propertiesByCode,
                                                    elementsNames: glueTable.elementsByCode)

        let glueClasses = GlueClasses(insertionSpecifierType: AEInsertion.self, objectSpecifierType: AEItem.self,
                                      multiObjectSpecifierType: AEItems.self, rootSpecifierType: AERoot.self,
                                      applicationType: AERoot.self, symbolType: AESymbol.self, formatter: specifierFormatter) // TO DO: check how this unpacks (c.f. py-appscript, should be fine as long as there's a native wrapper around specifier and a formatter that knows how to navigate and format both native and Swift values)
        super.init(target: applicationURL == nil ? .none : .url(applicationURL!),
                   launchOptions: defaultLaunchOptions, relaunchMode: defaultRelaunchMode, glueClasses: glueClasses)
    }
    
    
    required init(target: TargetApplication, launchOptions: LaunchOptions, relaunchMode: RelaunchMode, glueClasses: GlueClasses) { // TO DO: nasty (also, we really want ability to supply TargetApplication ourselves, e.g. when creating an app object using name/bundle ID/process ID instead of absolute path/remote address [file/eppc URL])
        // TO DO: having to pass GlueClasses argument (even if it's only the default static AEApplication glue) is annoying; how much useful functionality does AppData really provide us with, versus rolling an independent DynamicAppData class containing only what we need? [question is whether we need to bridge native dynamic queries to static SwiftAutomation APIs, e.g. when writing primitive libraries, embedding native runtime in Swift apps, or transpiling native code to Swift]
        fatalError()
    }
    
    func interfaceForCommand(term: CommandTerm) -> HandlerInterface {
        if let interface = self.commandInterfaces[term.name] { return interface }
        let interface = HandlerInterface(name: Symbol(term.name),
                                         parameters: term.parameters.map{ (Symbol($0.name), nullSymbol, asValue) },
                                         result: asIs)
        commandInterfaces[term.name] = interface
        return interface
    }
    
    func descriptor(for symbol: Symbol) -> Descriptor? {
        return self.glueTable.typesByName[symbol.key]
    }
    
    func symbol(for code: OSType) -> Symbol {
        if let name = self.glueTable.typesByCode[code] {
            return Symbol(name)
        } else {
            return Symbol(String(format: "0x%08x", code)) // TO DO: how should raw AE codes be presented?
        }
    }
}


let nullAppData = try! NativeAppData()

