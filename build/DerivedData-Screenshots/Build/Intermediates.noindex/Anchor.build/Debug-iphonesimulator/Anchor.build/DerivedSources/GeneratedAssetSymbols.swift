import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AnchorAccent" asset catalog color resource.
    static let anchorAccent = DeveloperToolsSupport.ColorResource(name: "AnchorAccent", bundle: resourceBundle)

    /// The "AnchorBackground" asset catalog color resource.
    static let anchorBackground = DeveloperToolsSupport.ColorResource(name: "AnchorBackground", bundle: resourceBundle)

    /// The "AnchorCard" asset catalog color resource.
    static let anchorCard = DeveloperToolsSupport.ColorResource(name: "AnchorCard", bundle: resourceBundle)

    /// The "AnchorSubBg" asset catalog color resource.
    static let anchorSubBg = DeveloperToolsSupport.ColorResource(name: "AnchorSubBg", bundle: resourceBundle)

    /// The "LaunchScreenBackground" asset catalog color resource.
    static let launchScreenBackground = DeveloperToolsSupport.ColorResource(name: "LaunchScreenBackground", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "BlockPresetInstagram" asset catalog image resource.
    static let blockPresetInstagram = DeveloperToolsSupport.ImageResource(name: "BlockPresetInstagram", bundle: resourceBundle)

    /// The "BlockPresetNetflix" asset catalog image resource.
    static let blockPresetNetflix = DeveloperToolsSupport.ImageResource(name: "BlockPresetNetflix", bundle: resourceBundle)

    /// The "BlockPresetTikTok" asset catalog image resource.
    static let blockPresetTikTok = DeveloperToolsSupport.ImageResource(name: "BlockPresetTikTok", bundle: resourceBundle)

    /// The "BlockPresetX" asset catalog image resource.
    static let blockPresetX = DeveloperToolsSupport.ImageResource(name: "BlockPresetX", bundle: resourceBundle)

    /// The "SplashIcon" asset catalog image resource.
    static let splashIcon = DeveloperToolsSupport.ImageResource(name: "SplashIcon", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "AnchorAccent" asset catalog color.
    static var anchorAccent: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .anchorAccent)
#else
        .init()
#endif
    }

    /// The "AnchorBackground" asset catalog color.
    static var anchorBackground: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .anchorBackground)
#else
        .init()
#endif
    }

    /// The "AnchorCard" asset catalog color.
    static var anchorCard: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .anchorCard)
#else
        .init()
#endif
    }

    /// The "AnchorSubBg" asset catalog color.
    static var anchorSubBg: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .anchorSubBg)
#else
        .init()
#endif
    }

    /// The "LaunchScreenBackground" asset catalog color.
    static var launchScreenBackground: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .launchScreenBackground)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "AnchorAccent" asset catalog color.
    static var anchorAccent: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .anchorAccent)
#else
        .init()
#endif
    }

    /// The "AnchorBackground" asset catalog color.
    static var anchorBackground: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .anchorBackground)
#else
        .init()
#endif
    }

    /// The "AnchorCard" asset catalog color.
    static var anchorCard: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .anchorCard)
#else
        .init()
#endif
    }

    /// The "AnchorSubBg" asset catalog color.
    static var anchorSubBg: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .anchorSubBg)
#else
        .init()
#endif
    }

    /// The "LaunchScreenBackground" asset catalog color.
    static var launchScreenBackground: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .launchScreenBackground)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "AnchorAccent" asset catalog color.
    static var anchorAccent: SwiftUI.Color { .init(.anchorAccent) }

    /// The "AnchorBackground" asset catalog color.
    static var anchorBackground: SwiftUI.Color { .init(.anchorBackground) }

    /// The "AnchorCard" asset catalog color.
    static var anchorCard: SwiftUI.Color { .init(.anchorCard) }

    /// The "AnchorSubBg" asset catalog color.
    static var anchorSubBg: SwiftUI.Color { .init(.anchorSubBg) }

    /// The "LaunchScreenBackground" asset catalog color.
    static var launchScreenBackground: SwiftUI.Color { .init(.launchScreenBackground) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "AnchorAccent" asset catalog color.
    static var anchorAccent: SwiftUI.Color { .init(.anchorAccent) }

    /// The "AnchorBackground" asset catalog color.
    static var anchorBackground: SwiftUI.Color { .init(.anchorBackground) }

    /// The "AnchorCard" asset catalog color.
    static var anchorCard: SwiftUI.Color { .init(.anchorCard) }

    /// The "AnchorSubBg" asset catalog color.
    static var anchorSubBg: SwiftUI.Color { .init(.anchorSubBg) }

    /// The "LaunchScreenBackground" asset catalog color.
    static var launchScreenBackground: SwiftUI.Color { .init(.launchScreenBackground) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "BlockPresetInstagram" asset catalog image.
    static var blockPresetInstagram: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .blockPresetInstagram)
#else
        .init()
#endif
    }

    /// The "BlockPresetNetflix" asset catalog image.
    static var blockPresetNetflix: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .blockPresetNetflix)
#else
        .init()
#endif
    }

    /// The "BlockPresetTikTok" asset catalog image.
    static var blockPresetTikTok: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .blockPresetTikTok)
#else
        .init()
#endif
    }

    /// The "BlockPresetX" asset catalog image.
    static var blockPresetX: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .blockPresetX)
#else
        .init()
#endif
    }

    /// The "SplashIcon" asset catalog image.
    static var splashIcon: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .splashIcon)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "BlockPresetInstagram" asset catalog image.
    static var blockPresetInstagram: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .blockPresetInstagram)
#else
        .init()
#endif
    }

    /// The "BlockPresetNetflix" asset catalog image.
    static var blockPresetNetflix: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .blockPresetNetflix)
#else
        .init()
#endif
    }

    /// The "BlockPresetTikTok" asset catalog image.
    static var blockPresetTikTok: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .blockPresetTikTok)
#else
        .init()
#endif
    }

    /// The "BlockPresetX" asset catalog image.
    static var blockPresetX: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .blockPresetX)
#else
        .init()
#endif
    }

    /// The "SplashIcon" asset catalog image.
    static var splashIcon: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .splashIcon)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

