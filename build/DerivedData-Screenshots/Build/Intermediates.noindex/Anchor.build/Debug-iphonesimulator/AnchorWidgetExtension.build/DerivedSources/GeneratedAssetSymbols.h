#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.rbqls6651.anchor.widget";

/// The "AnchorAccent" asset catalog color resource.
static NSString * const ACColorNameAnchorAccent AC_SWIFT_PRIVATE = @"AnchorAccent";

/// The "AnchorBackground" asset catalog color resource.
static NSString * const ACColorNameAnchorBackground AC_SWIFT_PRIVATE = @"AnchorBackground";

/// The "AnchorCard" asset catalog color resource.
static NSString * const ACColorNameAnchorCard AC_SWIFT_PRIVATE = @"AnchorCard";

/// The "AnchorSubBg" asset catalog color resource.
static NSString * const ACColorNameAnchorSubBg AC_SWIFT_PRIVATE = @"AnchorSubBg";

#undef AC_SWIFT_PRIVATE
