import XCTest
@testable import XiaoLengBox

final class PresetCatalogTests: XCTestCase {

    func testAllPresetCategoriesNotEmpty() {
        XCTAssertFalse(PresetCatalog.allPresetCategories.isEmpty)
        for category in PresetCatalog.allPresetCategories {
            XCTAssertFalse(category.name.isEmpty)
            XCTAssertFalse(category.icon.isEmpty)
            XCTAssertFalse(category.tools.isEmpty)
        }
    }

    func testAICategoryExists() {
        let ai = PresetCatalog.allPresetCategories.first { $0.name == "AI Harness" }
        XCTAssertNotNil(ai)
        XCTAssertEqual(ai?.icon, "brain.head.profile")
        XCTAssertTrue((ai?.tools.count ?? 0) >= 4)
    }

    func testNetSecCategoryExists() {
        let sec = PresetCatalog.allPresetCategories.first { $0.name == "NetSec Scanner" }
        XCTAssertNotNil(sec)
        XCTAssertEqual(sec?.icon, "shield.lefthalf.filled")
        XCTAssertTrue((sec?.tools.count ?? 0) >= 10)
    }

    func testDevToolsCategoryExists() {
        let dev = PresetCatalog.allPresetCategories.first { $0.name == "DevTools" }
        XCTAssertNotNil(dev)
        XCTAssertEqual(dev?.icon, "hammer.fill")
    }

    func testFindPresetTool() {
        let nmap = PresetCatalog.findPresetTool(id: "nmap")
        XCTAssertNotNil(nmap)
        XCTAssertEqual(nmap?.name, "nmap")
        XCTAssertFalse(nmap?.installHint.isEmpty ?? true)

        let fake = PresetCatalog.findPresetTool(id: "nonexistent")
        XCTAssertNil(fake)
    }

    func testInstallHint() {
        let hint = PresetCatalog.installHint(for: "nmap")
        XCTAssertNotNil(hint)
        XCTAssertTrue(hint?.contains("brew") ?? false)
    }

    func testAllToolIdsUnique() {
        var ids = Set<String>()
        for category in PresetCatalog.allPresetCategories {
            for tool in category.tools {
                XCTAssertTrue(ids.insert(tool.id).inserted, "Duplicate tool ID: \(tool.id)")
            }
        }
    }

    func testAllToolsHaveSearchPaths() {
        for category in PresetCatalog.allPresetCategories {
            for tool in category.tools {
                XCTAssertFalse(tool.searchPaths.isEmpty, "\(tool.name) has no search paths")
            }
        }
    }
}
