//
//  zpledApp.swift
//  zpled
//
//  Created by Peter Richardson on 8/19/25.
//
import SwiftUI

@main
struct ZPLEdApp: App {
    @StateObject private var templateStore = TemplateStore.shared

    var body: some Scene {
        // Editor window that accepts an optional String value
        WindowGroup("ZPL Editor", for: String.self) { $initialZPL in
            ContentView(initialText: initialZPL)
        }
        .defaultSize(width: 900, height: 600)
        .windowResizability(.contentSize)

        // Add the “New from Template” menu under File
        .commands {
            TemplateCommands()
        }
    }
}

// Commands live outside of the Scene body for clarity
struct TemplateCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject private var templateStore = TemplateStore.shared

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Menu("New from Template") {
                ForEach(Array(templateStore.templates.enumerated()), id: \.1.id) { idx, t in
                    templateButton(idx: idx, t: t)
                }

                Divider()
                Button("Reload Templates") { templateStore.reload() }
                    .keyboardShortcut("R", modifiers: [.command, .shift])
            }
        }
    }

    // ⌘⇧1 … ⌘⇧9 for first 9 items; others get no shortcut
    private func shortcutForIndex(_ index: Int) -> KeyEquivalent? {
        guard (0..<9).contains(index) else { return nil }
        return KeyEquivalent(Character(String(index + 1)))
    }

    @ViewBuilder
    private func templateButton(idx: Int, t: ZPLTemplate) -> some View {
        if let key = shortcutForIndex(idx) {
            Button(t.displayName) { openWindow(value: t.contents) }
                .keyboardShortcut(key, modifiers: [.command, .option])
        } else {
            Button(t.displayName) { openWindow(value: t.contents) }
        }
    }
}
