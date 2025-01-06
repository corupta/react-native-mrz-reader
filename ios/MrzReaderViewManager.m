#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(MrzReaderViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(docType, NSString)
RCT_EXPORT_VIEW_PROPERTY(cameraSelector, NSString)
RCT_EXPORT_VIEW_PROPERTY(onMRZRead, RCTDirectEventBlock)

@end
