import Foundation

enum ImageFileStoreError: Error, Equatable {
    case invalidRelativePath
}

struct ImageFileStore {
    private let rootDirectory: URL
    private let fileManager: FileManager

    init(rootDirectory: URL, fileManager: FileManager = .default) {
        self.rootDirectory = rootDirectory.standardizedFileURL
        self.fileManager = fileManager
    }

    func save(_ data: Data, fileExtension: String) throws -> String {
        let directory = rootDirectory.appending(path: "Images", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let filename = "\(UUID().uuidString).\(fileExtension)"
        let url = directory.appending(path: filename)
        try data.write(to: url, options: .atomic)
        return "Images/\(filename)"
    }

    func load(relativePath: String) throws -> Data {
        try Data(contentsOf: validatedURL(for: relativePath))
    }

    func delete(relativePath: String) throws {
        let url = try validatedURL(for: relativePath)
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    func exists(relativePath: String) -> Bool {
        guard let url = try? validatedURL(for: relativePath) else { return false }
        return fileManager.fileExists(atPath: url.path)
    }

    private func validatedURL(for relativePath: String) throws -> URL {
        guard !relativePath.hasPrefix("/"), !relativePath.split(separator: "/").contains("..") else {
            throw ImageFileStoreError.invalidRelativePath
        }
        let url = rootDirectory.appending(path: relativePath).standardizedFileURL
        guard url.path.hasPrefix(rootDirectory.path + "/") else {
            throw ImageFileStoreError.invalidRelativePath
        }
        return url
    }
}
