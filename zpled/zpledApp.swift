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
            // This injects into the built-in File menu
            CommandGroup(after: .newItem) {
                Menu("New from Template") {
                    if templateStore.templates.isEmpty {
                        Text("No templates found").foregroundStyle(.secondary)
                    } else {
                        ForEach(templateStore.templates) { t in
                            Button(t.displayName) {
                                openWindow(value: t.contents)
                            }
                        }
                    }
                    Divider()
                    Button("Reload Templates") {
                        templateStore.reload()
                    }
                    .keyboardShortcut("R", modifiers: [.command, .shift])
                }
            }
        }
}
