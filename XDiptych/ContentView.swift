//
//  ContentView.swift
//  XDiptych
//
//  Created by Nathan Darma on 7/6/2025.
//

import SwiftUI
import PhotosUI // Import PhotosUI

enum AspectRatioOption: String, CaseIterable, Identifiable {
    case square = "1:1"
    case standard = "4:3"
    case wide = "16:9"
    case photo = "3:2"

    var id: String { self.rawValue }

    var ratioValue: CGFloat {
        switch self {
        case .square: return 1.0
        case .standard: return 4.0 / 3.0
        case .wide: return 16.0 / 9.0
        case .photo: return 3.0 / 2.0
        }
    }
}

struct ContentView: View {
    // Removed old state variables for individual images and photo items
    @State private var diptychImage: UIImage?
    @State private var selectedAspectRatio: AspectRatioOption = .square
    @State private var showPicker1 = false // To control first picker presentation
    @State private var showPicker2 = false // To control second picker presentation

    // New state variables using AdjustableImage
    @State private var adjImage1 = AdjustableImage()
    @State private var adjImage2 = AdjustableImage()

    var body: some View {
        // Main VStack
        VStack {
            // Top row of buttons for image selection
            HStack {
                Button("Select Image 1") {
                    showPicker1 = true
                }
                Spacer() // Pushes buttons to the sides
                Button("Select Image 2") {
                    showPicker2 = true
                }
            }
            .padding(.horizontal) // Padding for the button row

            // HStack for the two interactive image views
            HStack(spacing: 2) { // spacing: 2 for a small gap, 0 for touching borders
                InteractiveImageView(adjustableImage: $adjImage1)
                InteractiveImageView(adjustableImage: $adjImage2)
            }
            .frame(height: 300) // Define a height for the interactive area
            .padding(.horizontal) // Padding for the interactive image area

            // Display area for the final processed diptych (output of ImageProcessor)
            // This is intentionally kept separate to show that live adjustments
            // in InteractiveImageView are now reflected in the final diptych by ImageProcessor.
            Group {
                Text("Final Diptych Preview:").font(.caption).padding(.top) // Updated text
                if let diptych = diptychImage {
                    Image(uiImage: diptych)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 150)
                        .border(Color.black, width: 1) // Updated border
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.05))
                        .frame(maxWidth: .infinity, maxHeight: 150)
                        .overlay(Text("Final Diptych").foregroundColor(.gray)) // Updated text
                        .border(Color.gray.opacity(0.5))
                }
            }
            .padding(.horizontal)

            Picker("Aspect Ratio", selection: $selectedAspectRatio) {
                ForEach(AspectRatioOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .padding() // Added padding for visual separation

            Spacer() // Pushes content to the top
        }
        .photosPicker(isPresented: $showPicker1, selection: $adjImage1.photosItem, matching: .images) // Bind to adjImage1.photosItem
        .photosPicker(isPresented: $showPicker2, selection: $adjImage2.photosItem, matching: .images) // Bind to adjImage2.photosItem
        .onChange(of: adjImage1.photosItem) { _ in
            Task {
                if let photosItem = adjImage1.photosItem,
                   let data = try? await photosItem.loadTransferable(type: Data.self) {
                    adjImage1.image = UIImage(data: data)
                    adjImage1.scale = 1.0 // Reset scale and offset
                    adjImage1.offset = .zero
                } else {
                    adjImage1.image = nil // Clear image if item is nil or loading failed
                }
                generateDiptych()
            }
        }
        .onChange(of: adjImage2.photosItem) { _ in
            Task {
                if let photosItem = adjImage2.photosItem,
                   let data = try? await photosItem.loadTransferable(type: Data.self) {
                    adjImage2.image = UIImage(data: data)
                    adjImage2.scale = 1.0 // Reset scale and offset
                    adjImage2.offset = .zero
                } else {
                    adjImage2.image = nil // Clear image if item is nil or loading failed
                }
                generateDiptych()
            }
        }
        // Removed onChange(of: selectedImage1) and selectedImage2 as they are now part of adjImageX
        .onChange(of: selectedAspectRatio) { _ in generateDiptych() }
        .onChange(of: adjImage1.scale) { _ in generateDiptych() } // Added for scale/offset
        .onChange(of: adjImage1.offset) { _ in generateDiptych() }
        .onChange(of: adjImage2.scale) { _ in generateDiptych() }
        .onChange(of: adjImage2.offset) { _ in generateDiptych() }
        .onAppear {
            generateDiptych()
        }
    }

    private func generateDiptych() {
        // Updated to use adjImage1.image and adjImage2.image
        // and pass the full adjImage1 and adjImage2 structs
        guard adjImage1.image != nil, adjImage2.image != nil else {
            self.diptychImage = nil
            return
        }

        // Consider performing on a background thread for real apps
        self.diptychImage = ImageProcessor.createDiptych(
            adjImage1: self.adjImage1, // Pass the full struct
            adjImage2: self.adjImage2, // Pass the full struct
            targetAspectRatio: selectedAspectRatio.ratioValue,
            outputHeight: 1200 // Default height, can be configurable later
        )
    }
}

// Preview removed as per instructions

// Define InteractiveImageView as a private struct within ContentView
private struct InteractiveImageView: View {
    @Binding var adjustableImage: AdjustableImage

    // Temporary states for gestures
    @State private var currentDragOffset: CGSize = .zero
    @State private var currentMagnification: CGFloat = 1.0

    // Committed states for gestures
    @State private var committedDragOffset: CGSize = .zero
    @State private var committedScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            if let img = adjustableImage.image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .scaleEffect(committedScale * currentMagnification)
                    .offset(x: committedDragOffset.width + currentDragOffset.width,
                            y: committedDragOffset.height + currentDragOffset.height)
                    .clipped()
                    .border(Color.gray)
                    .contentShape(Rectangle()) // For gesture hit testing
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                currentDragOffset = value.translation
                            }
                            .onEnded { value in
                                committedDragOffset.width += value.translation.width
                                committedDragOffset.height += value.translation.height
                                adjustableImage.offset = committedDragOffset // Update binding
                                currentDragOffset = .zero // Reset temporary offset
                            }
                    )
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                currentMagnification = value
                            }
                            .onEnded { value in
                                committedScale *= value
                                // Clamp the scale
                                committedScale = max(0.5, min(committedScale, 3.0))
                                adjustableImage.scale = committedScale // Update binding
                                currentMagnification = 1.0 // Reset temporary magnification
                            }
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .border(Color.gray)
                    .overlay(Text("Select Image").foregroundColor(.gray))
            }
        }
        // This onChange is important to reset gesture states when a new image is selected
        // and adjImage.scale is programmatically reset to 1.0
        .onChange(of: adjustableImage.image) { _ in // if image changes, reset internal gesture states
            committedScale = 1.0
            currentMagnification = 1.0
            committedDragOffset = .zero
            currentDragOffset = .zero
            // Sync binding if necessary, though scale/offset on adjustableImage are reset externally
            adjustableImage.scale = 1.0
            adjustableImage.offset = .zero
        }
        // This ensures that if the binding `adjustableImage.scale` is reset from outside,
        // `committedScale` also resets.
        .onChange(of: adjustableImage.scale) { newScale in
             if newScale == 1.0 {
                 self.committedScale = 1.0
                 self.currentMagnification = 1.0
             }
        }
        .onChange(of: adjustableImage.offset) { newOffset in
             if newOffset == .zero {
                 self.committedDragOffset = .zero
                 self.currentDragOffset = .zero
             }
        }
    }
}
