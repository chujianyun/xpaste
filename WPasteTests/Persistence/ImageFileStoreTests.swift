import Foundation
import Testing
@testable import WPaste

struct ImageFileStoreTests {
    @Test func savesLoadsAndDeletesRelativeImagePath() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = ImageFileStore(rootDirectory: root)

        let relativePath = try store.save(Data([1, 2, 3]), fileExtension: "png")

        #expect(relativePath.hasPrefix("Images/"))
        #expect(try store.load(relativePath: relativePath) == Data([1, 2, 3]))
        try store.delete(relativePath: relativePath)
        #expect(store.exists(relativePath: relativePath) == false)
    }

    @Test func rejectsPathsOutsideStoreRoot() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = ImageFileStore(rootDirectory: root)
        #expect(throws: ImageFileStoreError.invalidRelativePath) {
            try store.load(relativePath: "../secret")
        }
    }
}

