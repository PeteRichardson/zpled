//
//  Templates.swift
//  zpled
//
//  Created by Peter Richardson on 8/20/25.
//

import Foundation

struct ZPLTemplate: Identifiable, Hashable {
    let id = UUID()
    let displayName: String
    let contents: String
}

@MainActor
final class TemplateStore: ObservableObject {
    static let shared = TemplateStore()

    @Published private(set) var templates: [ZPLTemplate] = []

    private init() {
        reload()
    }

    func reload() {
        var found: [ZPLTemplate] = []
        if let urls = Bundle.main.urls(forResourcesWithExtension: "zpl", subdirectory: "Templates") {
            for url in urls {
                if let data = try? Data(contentsOf: url),
                   let text = String(data: data, encoding: .utf8) {
                    let base = url.deletingPathExtension().lastPathComponent
                    let name = base.replacingOccurrences(of: "_", with: " ")
                    found.append(ZPLTemplate(displayName: name, contents: text))
                }
            }
        }
        // Sort alphabetically
        templates = found.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
}
