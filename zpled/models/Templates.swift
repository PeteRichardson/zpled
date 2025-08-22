//
//  Templates.swift
//  zpled
//
//  Created by Peter Richardson on 8/20/25.
//

import Foundation

struct ZPLTemplate: Identifiable, Hashable {
    let id = UUID()
    let order: Int?          // parsed order prefix, if present
    let displayName: String  // clean name (without prefix)
    let contents: String
}

@MainActor
final class TemplateStore: ObservableObject {
    
    public static let defaultZPL : String = """
^XA

^FO20,40
^A0N,80,80
^FDZPL Editor^FS

^FO20,120
^A0N,80,80
^FDTest!^FS

^XZ
"""
    
    static let shared = TemplateStore()
    @Published private(set) var templates: [ZPLTemplate] = []

    private init() { reload() }

    func reload() {
        var found: [ZPLTemplate] = []

        if let urls = Bundle.main.urls(forResourcesWithExtension: "zpl",
                                       subdirectory: "Templates") {
            for url in urls {
                if let data = try? Data(contentsOf: url),
                   let text = String(data: data, encoding: .utf8) {

                    let base = url.deletingPathExtension().lastPathComponent
                    let (order, name) = parseName(base)
                    found.append(ZPLTemplate(order: order, displayName: name, contents: text))
                }
            }
        }

        // Sort: first by order if present, then alphabetically
        templates = found.sorted {
            switch ($0.order, $1.order) {
            case let (l?, r?):
                return l < r
            case (.some, nil):
                return true
            case (nil, .some):
                return false
            default:
                return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
        }
    }

    private func parseName(_ filename: String) -> (Int?, String) {
        // Match "number_restOfName"
        let parts = filename.split(separator: "_", maxSplits: 1, omittingEmptySubsequences: false)
        let rawName: String
        var order: Int? = nil

        if parts.count == 2, let n = Int(parts[0]) {
            order = n
            rawName = String(parts[1])
        } else {
            rawName = filename
        }

        // Prettify: underscores → spaces, capitalize words
        let words = rawName.split(separator: "_").map { word in
            word.prefix(1).uppercased() + word.dropFirst()
        }
        let prettyName = words.joined(separator: " ")

        return (order, prettyName)
    }
}
