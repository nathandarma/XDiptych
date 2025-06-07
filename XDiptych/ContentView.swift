//
//  ContentView.swift
//  XDiptych
//
//  Created by Nathan Darma on 7/6/2025.
//

import SwiftUI
import PhotosUI // Import PhotosUI
import UIKit // Ensure UIKit is imported for UIColor and potentially UIImageWriteToSavedPhotosAlbum if not transitively

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
    // Frame customization state variables
    @State private var frameColor: Color = .black // Default to black for dark theme
    @State private var frameThickness: CGFloat = 0.0
    // State for save feedback
    @State private var showSaveConfirmation = false
    @State private var saveMessage = ""
    @State private var imageSaver = ImageSaver() // Instance of the helper
    @State private var showPicker1 = false // To control first picker presentation
    @State private var showPicker2 = false // To control second picker presentation

    // New state variables using AdjustableImage
    @State private var adjImage1 = AdjustableImage()
    @State private var adjImage2 = AdjustableImage()

    var body: some View {
        ZStack { // Use ZStack to layer background
            Color.black.edgesIgnoringSafeArea(.all) // Dark background

            ScrollView { // Ensure content is scrollable
                VStack { // Main content VStack
                    // 1. Interactive Image Previews
                    HStack(spacing: 2) {
                        InteractiveImageView(adjustableImage: $adjImage1)
                        InteractiveImageView(adjustableImage: $adjImage2)
                    }
                    .frame(height: 300)
                    .padding(.vertical)

                    // 2. Control Panel (Form)
                    Form {
                        Section(header: Text("Image Selection").foregroundColor(.gray)) {
                            Button { showPicker1 = true } label: {
                                Label("Select Image 1", systemImage: "photo.on.rectangle.angled")
                                    .padding(.vertical, 6)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .buttonStyle(.bordered)
                            // .tint(.gray) // Using default tint for bordered in dark mode often works well

                            Button { showPicker2 = true } label: {
                                Label("Select Image 2", systemImage: "photo.on.rectangle.angled")
                                    .padding(.vertical, 6)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .buttonStyle(.bordered)
                            // .tint(.gray)
                        }

                        Section(header: Text("Diptych Settings").foregroundColor(.gray)) {
                            Picker("Aspect Ratio", selection: $selectedAspectRatio) {
                                ForEach(AspectRatioOption.allCases) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            // .pickerStyle(.segmented) // Consider for fewer options
                        }

                        Section(header: Text("Frame Settings").foregroundColor(.gray)) {
                            ColorPicker("Frame Color", selection: $frameColor)
                            VStack(alignment: .leading) {
                                Text("Frame Thickness: \(frameThickness, specifier: "%.0f") pts")
                                Slider(value: $frameThickness, in: 0...50, step: 1)
                            }
                        }

                        // Save Button inside the Form for grouping
                        Section {
                             Button(action: {
                                if let imageToSave = diptychImage {
                                    imageSaver.successHandler = {
                                        self.saveMessage = "Image saved successfully!"
                                        self.showSaveConfirmation = true
                                    }
                                    imageSaver.errorHandler = { error in
                                        self.saveMessage = "Error saving image: \(error?.localizedDescription ?? "Unknown error")"
                                        self.showSaveConfirmation = true
                                    }
                                    imageSaver.writeToPhotoAlbum(image: imageToSave)
                                }
                            }) {
                                Label("Save Diptych", systemImage: "square.and.arrow.down")
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 12) // Adjusted padding
                                    .padding(.vertical, 10)  // Adjusted padding
                                    .frame(maxWidth: .infinity)
                                    .background(Color.accentColor) // Use accent color
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            // .buttonStyle(.borderedProminent) // Removed to use custom styling
                            .disabled(diptychImage == nil)
                            .listRowInsets(EdgeInsets()) // Attempt to make button background extend to edges if needed
                        }
                    }
                    .frame(maxHeight: 450) // Give Form a reasonable maxHeight; ScrollView handles overflow
                    .background(Color.black) // Ensure Form background is dark if it defaults otherwise
                    .scrollContentBackground(.hidden) // For iOS 16+, to make Form background transparent if needed


                    // 3. Final Diptych Preview
                    Group {
                        Text("Final Diptych Preview:")
                            .font(.headline) // Make it a bit more prominent
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top)
                        if let diptych = diptychImage {
                            Image(uiImage: diptych)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200) // Slightly larger preview if space allows
                                .border(Color.gray, width: 1)
                        } else {
                            Rectangle()
                                .fill(Color(white: 0.15))
                                .frame(maxWidth: .infinity, maxHeight: 200)
                                .overlay(Text("Final Diptych").foregroundColor(.white.opacity(0.7)))
                                .border(Color.gray.opacity(0.5))
                        }
                    }
                    .padding(.vertical)

                    Spacer() // Pushes content up if ScrollView is not full
                } // End of Main VStack
                .padding(.horizontal) // Add horizontal padding to the main VStack content
            } // End of ScrollView
        } // End of ZStack
        .alert(isPresented: $showSaveConfirmation) {
            Alert(title: Text("Save Status"), message: Text(saveMessage), dismissButton: .default(Text("OK")))
        }
        .photosPicker(isPresented: $showPicker1, selection: $adjImage1.photosItem, matching: .images)
        .photosPicker(isPresented: $showPicker2, selection: $adjImage2.photosItem, matching: .images)
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
        .onChange(of: adjImage1.scale) { _ in generateDiptych() }
        .onChange(of: adjImage1.offset) { _ in generateDiptych() }
        .onChange(of: adjImage2.scale) { _ in generateDiptych() }
        .onChange(of: adjImage2.offset) { _ in generateDiptych() }
        .onChange(of: frameColor) { _ in generateDiptych() } // Added for frame color
        .onChange(of: frameThickness) { _ in generateDiptych() } // Added for frame thickness
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
        let uiColor = UIColor(self.frameColor) // Convert SwiftUI Color to UIColor
        self.diptychImage = ImageProcessor.createDiptych(
            adjImage1: self.adjImage1,
            adjImage2: self.adjImage2,
            targetAspectRatio: selectedAspectRatio.ratioValue,
            frameColor: uiColor,
            frameThickness: self.frameThickness,
            outputHeight: 1200
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

    // Gesture state for visual cues
    @GestureState private var isDragging: Bool = false
    @GestureState private var isMagnifying: Bool = false

    var body: some View {
        let isActive = isDragging || isMagnifying
        GeometryReader { geometry in
            ZStack { // Use ZStack to allow overlaying the reset button
                if let img = adjustableImage.image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .scaleEffect(committedScale * currentMagnification)
                        .offset(x: committedDragOffset.width + currentDragOffset.width,
                                y: committedDragOffset.height + currentDragOffset.height)
                        .clipped()
                        .border(isActive ? Color.accentColor : Color.gray, width: isActive ? 2 : 1) // Conditional border
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .updating($isDragging) { value, state, transaction in
                                    state = true
                                }
                                .onChanged { value in
                                    currentDragOffset = value.translation
                                }
                                .onEnded { value in
                                    committedDragOffset.width += value.translation.width
                                    committedDragOffset.height += value.translation.height
                                    adjustableImage.offset = committedDragOffset
                                    currentDragOffset = .zero
                                }
                        )
                        .gesture(
                            MagnificationGesture()
                                .updating($isMagnifying) { value, state, transaction in
                                    state = true
                                }
                                .onChanged { value in
                                    currentMagnification = value
                                }
                                .onEnded { value in
                                    committedScale *= value
                                    committedScale = max(0.5, min(committedScale, 3.0))
                                    adjustableImage.scale = committedScale
                                    currentMagnification = 1.0
                                }
                        )
                } else {
                    Rectangle()
                        .fill(Color(white: 0.15))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .border(Color.gray)
                    .overlay(Text("Select Image").foregroundColor(.white.opacity(0.7)))
                }

                // Reset Button Overlay
                if adjustableImage.image != nil && (adjustableImage.scale != 1.0 || adjustableImage.offset != .zero || committedScale != 1.0 || committedDragOffset != .zero) {
                    VStack {
                        HStack {
                            Spacer() // Pushes button to the trailing edge
                            Button {
                                adjustableImage.scale = 1.0
                                adjustableImage.offset = .zero
                                // Explicitly reset internal gesture states
                                committedScale = 1.0
                                currentMagnification = 1.0
                                committedDragOffset = .zero
                                currentDragOffset = .zero
                            } label: {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Color.accentColor)
                                    .padding(6) // Reduced padding
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(8) // Padding for the button from the corner
                        }
                        Spacer() // Pushes button to the top edge
                    }
                }
            } // End of ZStack for overlay
        } // End of GeometryReader
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
