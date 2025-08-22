//
//  LabelPreviewView.swift
//  zpled
//
//  Created by Peter Richardson on 8/21/25.
//

import SwiftUI

public struct LabelPreviewView: View {
    @Bindable var label : ZPLLabel
    @State public var isLoading = false
    @Binding var autoRefreshEnabled : Bool
    
    
    public var body: some View {
        VStack {
            HStack(spacing: 8) {
                Button {
                    label.refreshLabel()
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
                        label.refreshLabel()
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
                if let labelPreview  = label.previewImage {
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
    }
    
    
}



#Preview {
    let label = ZPLLabel(text: TemplateStore.defaultZPL)
    LabelPreviewView(label: label, autoRefreshEnabled: .constant(true))
}

