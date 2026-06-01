import Foundation
import Testing
@testable import yuedu_app

@Suite("App entitlement configuration")
struct AppEntitlementConfigurationTests {
    @Test("main app entitlements only include the configured app group")
    func mainAppEntitlementsOnlyIncludeAppGroup() throws {
        let entitlements = try loadMainAppEntitlements()

        #expect(entitlements["com.apple.developer.applesignin"] == nil)
        #expect(entitlements["com.apple.developer.icloud-services"] == nil)
        #expect(entitlements["com.apple.developer.icloud-container-identifiers"] == nil)
        #expect(entitlements["com.apple.security.application-groups"] as? [String] == [
            "group.com.mumu.yuedu"
        ])
    }

    private func loadMainAppEntitlements() throws -> [String: Any] {
        let fileURL = URL(fileURLWithPath: #filePath)
        let repoRoot = try #require(findRepoRoot(from: fileURL))
        let entitlementsURL = repoRoot.appendingPathComponent("iOS/Yuedu-Reader.entitlements")
        let data = try Data(contentsOf: entitlementsURL)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        return try #require(plist as? [String: Any])
    }

    private func findRepoRoot(from fileURL: URL) -> URL? {
        var candidate = fileURL.deletingLastPathComponent()
        while candidate.path != "/" {
            if FileManager.default.fileExists(
                atPath: candidate.appendingPathComponent("Yuedu-Reader.xcodeproj").path
            ) {
                return candidate
            }
            candidate.deleteLastPathComponent()
        }
        return nil
    }
}
