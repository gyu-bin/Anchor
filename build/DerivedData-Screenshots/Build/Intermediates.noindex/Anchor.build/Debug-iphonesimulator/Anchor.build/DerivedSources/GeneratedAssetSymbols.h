#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.rbqls6651.anchor";

/// The "AccentColor" asset catalog color resource.
static NSString * const ACColorNameAccentColor AC_SWIFT_PRIVATE = @"AccentColor";

/// The "AnchorAccent" asset catalog color resource.
static NSString * const ACColorNameAnchorAccent AC_SWIFT_PRIVATE = @"AnchorAccent";

/// The "AnchorBackground" asset catalog color resource.
static NSString * const ACColorNameAnchorBackground AC_SWIFT_PRIVATE = @"AnchorBackground";

/// The "AnchorCard" asset catalog color resource.
static NSString * const ACColorNameAnchorCard AC_SWIFT_PRIVATE = @"AnchorCard";

/// The "AnchorSubBg" asset catalog color resource.
static NSString * const ACColorNameAnchorSubBg AC_SWIFT_PRIVATE = @"AnchorSubBg";

/// The "LaunchScreenBackground" asset catalog color resource.
static NSString * const ACColorNameLaunchScreenBackground AC_SWIFT_PRIVATE = @"LaunchScreenBackground";

/// The "BlockPresetInstagram" asset catalog image resource.
static NSString * const ACImageNameBlockPresetInstagram AC_SWIFT_PRIVATE = @"BlockPresetInstagram";

/// The "BlockPresetNetflix" asset catalog image resource.
static NSString * const ACImageNameBlockPresetNetflix AC_SWIFT_PRIVATE = @"BlockPresetNetflix";

/// The "BlockPresetTikTok" asset catalog image resource.
static NSString * const ACImageNameBlockPresetTikTok AC_SWIFT_PRIVATE = @"BlockPresetTikTok";

/// The "BlockPresetX" asset catalog image resource.
static NSString * const ACImageNameBlockPresetX AC_SWIFT_PRIVATE = @"BlockPresetX";

/// The "SplashIcon" asset catalog image resource.
static NSString * const ACImageNameSplashIcon AC_SWIFT_PRIVATE = @"SplashIcon";

#undef AC_SWIFT_PRIVATE
