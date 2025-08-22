//
//  ContentView.swift
//  zpled
//
//  Created by Peter Richardson on 8/19/25.
//

import SwiftUI
import AppKit

private var editorFont: Font {
    // Try your named font first
    let name = "MonaspaceNeon-Regular"
    let size = 14.0
    if NSFont(name:name, size: size) != nil {
        return .custom(name, size: size)
    } else {
        return .system(.body, design: .serif)
    }
}



struct ContentView: View {
    //@State private var text: String
    @State private var label: ZPLLabel
    

    
    // New initializer lets callers pass initial text
    init(initialText: String? = nil) {
        _label = State(initialValue: ZPLLabel(text:  initialText ?? TemplateStore.defaultZPL))
    }
    
    private static let defaultDebounceDelay = Duration.milliseconds(800)
    
    @State private var autoRefreshTask: Task<Void, Never>? = nil
    @State private var autoRefreshEnabled = true
    
    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 12) {
                TextEditor(text: $label.text)
                    .environment(\.font, editorFont)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment:.topLeading)
                LabelPreviewView(label: label, autoRefreshEnabled: $autoRefreshEnabled)
                .frame(minWidth: 300, maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity)
            HStack {
                Spacer()
                Button("Print", systemImage: "paperplane.circle") {
                    label.refreshLabel()
                    sendZPL(label.text)
                }
            }
        }
        .padding()
        // Debounce only while auto-refresher is enabled
        .onChange(of: label.text) {
            if autoRefreshEnabled {
                scheduleAutoRefresh(delay: ContentView.defaultDebounceDelay)
            }
        }
        // React to toggling
        .onChange(of: autoRefreshEnabled) { oldValue, newValue in
            if newValue {
                scheduleAutoRefresh(delay: ContentView.defaultDebounceDelay)
            } else {
                autoRefreshTask?.cancel()
            }
        }
        // Refresh once on appear if enabled
        .task {
            if autoRefreshEnabled {
                label.refreshLabel()
            }
        }
    }
    
    private func scheduleAutoRefresh(delay: Duration = defaultDebounceDelay) {
        // Cancel any in-flight debounce task
        autoRefreshTask?.cancel()
        autoRefreshTask = Task { [label] in
            // Debounce window; if cancelled, exit without refreshing
            do {
                try await Task.sleep(for: delay)
            } catch {
                return // cancelled during sleep
            }
            guard !Task.isCancelled else { return }
            await MainActor.run {
                label.refreshLabel()
            }
        }
    }
    
    
}

#Preview {
    ContentView()
}
