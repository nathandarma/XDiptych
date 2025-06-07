import UIKit

struct ImageProcessor {

    // New renderPanel function
    private static func renderPanel(adjustableImage: AdjustableImage, panelSize: CGSize) -> UIImage? {
        guard let sourceImage = adjustableImage.image else {
            print("Error: sourceImage is nil in renderPanel.")
            return nil
        }

        let scale = adjustableImage.scale
        let offset = adjustableImage.offset // This is the offset of the image's top-left from panel's top-left

        // Calculate the size of the scaled image
        let scaledWidth = sourceImage.size.width * scale
        let scaledHeight = sourceImage.size.height * scale

        let renderer = UIGraphicsImageRenderer(size: panelSize)
        let renderedPanelImage = renderer.image { context in
            // The CGRect for drawing the sourceImage within the panel's coordinate system
            // The panel itself acts as a clipping boundary due to the renderer's context size.
            sourceImage.draw(in: CGRect(x: offset.width,
                                        y: offset.height,
                                        width: scaledWidth,
                                        height: scaledHeight))
        }
        return renderedPanelImage
    }

    // Updated createDiptych function
    static func createDiptych(adjImage1: AdjustableImage, adjImage2: AdjustableImage, targetAspectRatio: CGFloat, frameColor: UIColor, frameThickness: CGFloat, outputHeight: CGFloat = 1200) -> UIImage? {
        if outputHeight <= 0 { // targetAspectRatio can be 0 if totalWidth is used directly, but let's keep it positive for now.
             print("Error: outputHeight must be positive.")
             return nil
        }
        if targetAspectRatio <= 0 {
            print("Error: targetAspectRatio must be positive.")
            return nil
        }

        guard adjImage1.image != nil, adjImage2.image != nil else {
            print("Error: One or both input images are nil in createDiptych.")
            return nil
        }

        let totalWidth = outputHeight * targetAspectRatio
        guard totalWidth > 0 else {
            print("Error: Calculated totalWidth must be positive.")
            return nil
        }

        var panelContentWidth: CGFloat
        var panelContentHeight: CGFloat
        var panel1DrawRect: CGRect
        var panel2DrawRect: CGRect
        let actualFrameThickness = max(0, frameThickness) // Ensure frame thickness isn't negative

        if actualFrameThickness > 0 {
            // Check if frame thickness is too large for the output size.
            // Minimum 3 thickness lines horizontally, 2 vertically.
            if (actualFrameThickness * 3 >= totalWidth) || (actualFrameThickness * 2 >= outputHeight) {
                print("Warning: Frame thickness is too large for the output size. Drawing without frame.")
                // Fallback to drawing without frame by effectively setting thickness to 0 for calculations
                panelContentWidth = totalWidth / 2
                panelContentHeight = outputHeight
                panel1DrawRect = CGRect(x: 0, y: 0, width: panelContentWidth, height: panelContentHeight)
                panel2DrawRect = CGRect(x: panelContentWidth, y: 0, width: panelContentWidth, height: panelContentHeight)
            } else {
                panelContentWidth = (totalWidth - (3 * actualFrameThickness)) / 2
                panelContentHeight = outputHeight - (2 * actualFrameThickness)

                guard panelContentWidth > 0, panelContentHeight > 0 else {
                    print("Error: Frame thickness calculation resulted in zero or negative content width/height. Drawing without frame.")
                    // Fallback if calculations still go wrong
                    panelContentWidth = totalWidth / 2
                    panelContentHeight = outputHeight
                    panel1DrawRect = CGRect(x: 0, y: 0, width: panelContentWidth, height: panelContentHeight)
                    panel2DrawRect = CGRect(x: panelContentWidth, y: 0, width: panelContentWidth, height: panelContentHeight)
                } else {
                    panel1DrawRect = CGRect(x: actualFrameThickness, y: actualFrameThickness, width: panelContentWidth, height: panelContentHeight)
                    panel2DrawRect = CGRect(x: actualFrameThickness + panelContentWidth + actualFrameThickness, y: actualFrameThickness, width: panelContentWidth, height: panelContentHeight)
                }
            }
        } else {
            panelContentWidth = totalWidth / 2
            panelContentHeight = outputHeight
            panel1DrawRect = CGRect(x: 0, y: 0, width: panelContentWidth, height: panelContentHeight)
            panel2DrawRect = CGRect(x: panelContentWidth, y: 0, width: panelContentWidth, height: panelContentHeight)
        }

        let panelSize = CGSize(width: panelContentWidth, height: panelContentHeight)

        guard let processedImage1 = renderPanel(adjustableImage: adjImage1, panelSize: panelSize),
              let processedImage2 = renderPanel(adjustableImage: adjImage2, panelSize: panelSize) else {
            print("Error: Could not render one or both panels.")
            return nil
        }

        let finalSize = CGSize(width: totalWidth, height: outputHeight)
        let renderer = UIGraphicsImageRenderer(size: finalSize)
        let finalImage = renderer.image { context in
            if actualFrameThickness > 0 && !((actualFrameThickness * 3 >= totalWidth) || (actualFrameThickness * 2 >= outputHeight) || panelContentWidth <= 0 || panelContentHeight <= 0) {
                // Only fill with frame color if frame is actually being drawn
                frameColor.setFill()
                context.fill(CGRect(x: 0, y: 0, width: totalWidth, height: outputHeight))
            }
            processedImage1.draw(in: panel1DrawRect)
            processedImage2.draw(in: panel2DrawRect)
        }
        return finalImage
    }
}
