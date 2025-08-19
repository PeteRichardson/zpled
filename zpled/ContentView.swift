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
    @State private var text = """
^XA

^FO20,40
^A0N,80,80
^FDZPL Editor^FS

^FO20,120
^A0N,80,80
^FDTest!^FS

^XZ
"""
    
    private static let defaultDebounceDelay = Duration.milliseconds(800)
    
    @State private var labelPreview : NSImage?
    @State private var isLoading = false;
    @State private var errorMessage: String?
    @State private var autoRefreshTask: Task<Void, Never>? = nil
    @State private var pendingZPL: String? = nil
    @State private var autoRefreshEnabled = true
    
    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 12) {
                TextEditor(text: $text)
                    .environment(\.font, editorFont)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment:.topLeading)
                VStack {
                    HStack(spacing: 8) {
                        Button {
                            refreshLabel(zpl: text)
                        } label: {
                            Image(systemName: "arrow.clockwise.circle.fill")
                        }
                        .buttonStyle(.borderless)
                        
                        // Options menu
                        Menu {
                            Toggle(isOn: $autoRefreshEnabled) {
                                Label("Auto refresh", systemImage: autoRefreshEnabled ? "bolt.badge.clock" : "bolt.slash")
                            }
                            Divider()
                            Button("Refresh now", systemImage: "arrow.clockwise") {
                                refreshLabel(zpl: text)
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .menuStyle(.borderlessButton)
                        .menuIndicator(.hidden)
                        .fixedSize()
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    //.border(Color.gray.opacity(0.2), width: 1)
                    Group {
                        if let labelPreview {
                            Image(nsImage: labelPreview)
                                .resizable()
                                .interpolation(.none)   // keeps thermal-label “crisp”
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .scaledToFit()
                                .frame(maxWidth: 406, maxHeight: 203)
                                .shadow(radius: 8)
                            
                        } else if !isLoading {
                            ContentUnavailableView("No preview yet",
                                                   systemImage: "photo.on.rectangle.angled",
                                                   description: Text("Tap Refresh to generate a preview of your label"))
                            .frame(height: 200)
                        }
                    }
                    .padding()
                }
                .frame(minWidth: 300, maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity)
            HStack {
                Spacer()
                Button("Print", systemImage: "paperplane.circle") {
                    refreshLabel(zpl:text)
                    sendZPL(text)
                }
            }
        }
        .padding()
        // Debounce only while auto-refreshr is enabled
        .onChange(of: text) {
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
                refreshLabel(zpl: text)
            }
        }
    }
    
    private func scheduleAutoRefresh(delay: Duration = defaultDebounceDelay) {
        // Cancel any in-flight debounce task
        autoRefreshTask?.cancel()
        autoRefreshTask = Task { [text] in
            // Debounce window; if cancelled, exit without refreshing
            do {
                try await Task.sleep(for: delay)
            } catch {
                return // cancelled during sleep
            }
            guard !Task.isCancelled else { return }
            await MainActor.run {
                refreshLabel(zpl: text)
            }
        }
    }
    
    
    private func refreshLabel(zpl: String) {
        // If a refresh is already in progress, remember the latest ZPL and return
        if isLoading {
            pendingZPL = zpl
            return
        }
        isLoading = true
        errorMessage = nil
        labelPreview = nil
        
        Task {
            do {
                let data = try await fetchLabelImageData(
                    dpmm: 8,  // 203 dpi
                    widthMM: 50.8,  // 2.0"
                    heightMM: 25.4,  // 1.0"
                    zpl: zpl,
                    index: 0,
                    acceptMime: "image/png"   // PNG is simplest to display
                )
                
                guard let rendered = NSImage(data: data) else {
                    throw LabelaryError.emptyData
                }
                await MainActor.run { self.labelPreview = rendered }
            } catch {
                await MainActor.run { self.errorMessage = String(describing: error) }
            }
            await MainActor.run {
                self.isLoading = false
                if let next = self.pendingZPL {
                    self.pendingZPL = nil
                    // Re-run render for the latest pending ZPL once
                    self.refreshLabel(zpl: next)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
