import AppKit
import Testing

struct AppIconTests {
    @Test func applicationBundleContainsReadableAppIcon() throws {
        let bundle = Bundle.main
        let iconName = try #require(bundle.object(forInfoDictionaryKey: "CFBundleIconFile") as? String)
        let resourceName = (iconName as NSString).deletingPathExtension
        let iconURL = try #require(bundle.url(forResource: resourceName, withExtension: "icns"))
        let icon = try #require(NSImage(contentsOf: iconURL))
        #expect(icon.isValid)
        // Asset catalogs store larger renditions in Assets.car; the ICNS fallback is 256 px.
        #expect(icon.representations.contains { $0.pixelsWide >= 256 && $0.pixelsHigh >= 256 })
    }
}
