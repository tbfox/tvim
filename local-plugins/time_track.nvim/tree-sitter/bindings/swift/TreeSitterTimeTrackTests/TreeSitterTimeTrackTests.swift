import XCTest
import SwiftTreeSitter
import TreeSitterTimeTrack

final class TreeSitterTimeTrackTests: XCTestCase {
    func testCanLoadGrammar() throws {
        let parser = Parser()
        let language = Language(language: tree_sitter_time_track())
        XCTAssertNoThrow(try parser.setLanguage(language),
                         "Error loading TimeTrack grammar")
    }
}
