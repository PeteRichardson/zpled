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

^CWZ,E:PETEHANDWRITING.TTF

^FO20,40
^AZN,80,80
^FDPete:q
^FS

^FO20,120
^AZN,80,80
^FDRules!^FS

^XZ
"""
    
    var body: some View {
        VStack {
            TextEditor(text: $text)
                .environment(\.font, editorFont)
            HStack {
                Button("Send", systemImage: "paperplane.circle") {
                    Task {
                        do {
                            try await sendZPL(to: "192.168.0.133", zpl: $text.wrappedValue)
                            // Give the kernel a short window to finish transmitting before the process exits.
                            try await Task.sleep(nanoseconds: 200_000)  // 0.2µs grace period
                        } catch {
                            print("Error: \(error)")
                        }
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
