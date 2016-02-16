//
//  AppDelegate.swift
//  Splinter
//
//  Created by Max Bäumle on 16.02.16.
//  Copyright © 2016 Max Bäumle. All rights reserved.
//

import Cocoa
import Quartz

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        defer { NSApp.terminate(nil) }
        
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = [kUTTypePDF as String]
        openPanel.allowsMultipleSelection = true
        if (openPanel.runModal() != NSFileHandlingPanelOKButton) { return }
        
        application(NSApp, openFiles: openPanel.URLs.map({ $0.path! }))
    }

    func application(sender: NSApplication, openFiles filenames: [String]) {
        for path in filenames {
            let alert = NSAlert()
            alert.addButtonWithTitle("OK")
            alert.addButtonWithTitle("Cancel")
            alert.messageText = "Enter comma separated page ranges"
            alert.informativeText = (path as NSString).lastPathComponent
            let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
            textField.placeholderString = "2-4,8,14,17-18"
            alert.accessoryView = textField
            if alert.runModal() != NSAlertFirstButtonReturn { continue }
            
            var pageRanges = Array<Array<UInt32>>()
            
            let text = textField.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "0123456789,-").invertedSet)
            let components = text.componentsSeparatedByString(",")
            for component in components { pageRanges.append(component.componentsSeparatedByString("-").map({ UInt32($0)! })) }
            
            let printedPageRanges = printPDF(NSURL(fileURLWithPath: path), pageRanges: pageRanges)
            print("\(path): printed pages in ranges \(printedPageRanges)")
        }
        
        NSApp.terminate(nil)
    }
    
    func printPDF(fileURL: NSURL, pageRanges: Array<Array<UInt32>>) -> Array<Array<UInt32>> {
        // Create the document reference.
        guard let pdfDocument = PDFDocument(URL: fileURL) else { return [] }
        
        // Create the print settings.
        var printInfo = NSPrintInfo.sharedPrintInfo()
        
        let printPanel = NSPrintPanel()
        printPanel.options = [.ShowsCopies, .ShowsPageSetupAccessory]
        if printPanel.runModalWithPrintInfo(printInfo) != NSModalResponseOK { return [] }
        
        printInfo = printPanel.printInfo
        //print(printInfo)
        let printSettings = unsafeBitCast(printInfo.PMPrintSettings(), PMPrintSettings.self)
        
        var printedPageRanges = Array<Array<UInt32>>()
        
        for pageRange in pageRanges {
            guard let first = pageRange.first else { continue }
            guard let last = pageRange.last else { continue }
            
            if PMSetPageRange(printSettings, first, last) == OSStatus(kPMValueOutOfRange) { continue }
            
            PMSetFirstPage(printSettings, first, false)
            PMSetLastPage(printSettings, last, false)
            
            printInfo.updateFromPMPrintSettings()
            
            // Invoke private method.
            let autoRotate = true
            let op = pdfDocument.getPrintOperationForPrintInfo(printInfo, autoRotate: autoRotate)
            op.jobTitle = fileURL.lastPathComponent
            op.showsPrintPanel = false
            if op.runOperation() { printedPageRanges.append(pageRange) }
        }
        
        return printedPageRanges
    }

}

