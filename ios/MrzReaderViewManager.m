#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(MrzReaderViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(onMRZRead, RCTBubblingEventBlock)

@end
