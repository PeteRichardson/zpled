//
//  Label.swift
//  zpled
//
//  Created by Peter Richardson on 8/21/25.
//

import SwiftUI

@Observable class ZPLLabel: Identifiable {
    let id = UUID()
    var text: String
    var previewImage : NSImage? = nil
    private var pendingZPL: String? = nil
    private var errorMessage: String? = nil
    private var isLoading: Bool = false

    init(text: String) {
        self.text = text
    }
    
    func refreshLabel() {
        // If a refresh is already in progress, remember the latest ZPL and return
        if isLoading {
            pendingZPL = text
            return
        }
        errorMessage = nil
        isLoading = true
        previewImage = nil
        
        Task {
            do {
                let data = try await fetchLabelImageData(
                    dpmm: 8,  // 203 dpi
                    widthMM: 50.8,  // 2.0"
                    heightMM: 25.4,  // 1.0"
                    zpl: text,
                    index: 0,
                    acceptMime: "image/png"   // PNG is simplest to display
                )
                
                await MainActor.run {
                    guard let rendered = NSImage(data: data) else {
                        self.errorMessage = String(describing: LabelaryError.emptyData)
                        return
                    }
                    self.previewImage = rendered
                }
            } catch {
                await MainActor.run { self.errorMessage = String(describing: error) }
            }
            await MainActor.run {
                self.isLoading = false
                if self.pendingZPL != nil {
                    self.pendingZPL = nil
                    // Re-run render for the latest pending ZPL once
                    self.refreshLabel()
                }
            }
        }
    }
}

