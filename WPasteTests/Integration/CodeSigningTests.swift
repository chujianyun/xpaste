import Foundation
import Testing

struct CodeSigningTests {
    @Test func applicationUsesPinnedSigningIdentity() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = [
            "--verify", "--strict", "-R",
            "=identifier \"com.chujianyun.wpaste\" and anchor apple generic and certificate leaf = H\"DC86852A3142B093C0D6EF89F9978BC63349E0AF\"",
            Bundle.main.bundlePath
        ]
        let output = Pipe()
        process.standardError = output
        try process.run()
        let diagnostics = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        process.waitUntilExit()
        #expect(process.terminationStatus == 0, "App signature must match the pinned certificate: \(diagnostics)")
    }
}
