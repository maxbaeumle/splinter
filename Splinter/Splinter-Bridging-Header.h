//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

@import Quartz;

@interface PDFDocument (Private)

- (NSPrintOperation *)getPrintOperationForPrintInfo:(NSPrintInfo *)printInfo autoRotate:(BOOL)autoRotate;

@end

