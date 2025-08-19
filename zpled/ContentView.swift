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
^FDZPL^FS

^FO20,120
^A0N,80,80
^FDRules!^FS

^XZ
"""
    @State private var labelPreview : NSImage?
    @State private var isLoading = false;
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            HStack {
                TextEditor(text: $text)
                    .environment(\.font, editorFont)
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
                                               description: Text("Tap Render label"))
                            .frame(height: 200)
                    }
                }.padding()
            }
            HStack {
                HStack {
                    Button("Render label") { renderLabel(zpl:text) }
                        .buttonStyle(.borderedProminent)
                    if isLoading { ProgressView().controlSize(.small) }
                }
                Button("Send", systemImage: "paperplane.circle") {
                    renderLabel(zpl:text)
                    sendZPL(text)
                }
            }
        }
        .padding()
    }
    
    private func renderLabel(zpl: String) {
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
                await MainActor.run { self.isLoading = false }
            }
        }
}

#Preview {
    ContentView()
}
