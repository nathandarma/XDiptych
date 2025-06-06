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
    static func createDiptych(adjImage1: AdjustableImage, adjImage2: AdjustableImage, targetAspectRatio: CGFloat, outputHeight: CGFloat = 1200) -> UIImage? {
        if outputHeight <= 0 || targetAspectRatio <= 0 {
            print("Error: outputHeight and targetAspectRatio must be positive.")
            return nil
        }

        guard adjImage1.image != nil, adjImage2.image != nil else {
            print("Error: One or both input images are nil in createDiptych.")
            return nil
        }

        let totalWidth = outputHeight * targetAspectRatio
        let halfWidth = totalWidth / 2.0

        if halfWidth <= 0 {
            print("Error: Calculated panel width (halfWidth) must be positive.")
            return nil
        }

        let panelSize = CGSize(width: halfWidth, height: outputHeight)

        // Use renderPanel for each adjustable image
        guard let processedImage1 = renderPanel(adjustableImage: adjImage1, panelSize: panelSize) else {
            print("Error: Could not render panel for image1.")
            return nil
        }
        guard let processedImage2 = renderPanel(adjustableImage: adjImage2, panelSize: panelSize) else {
            print("Error: Could not render panel for image2.")
            return nil
        }

        let finalSize = CGSize(width: totalWidth, height: outputHeight)
        let renderer = UIGraphicsImageRenderer(size: finalSize)

        let diptychImage = renderer.image { context in
            processedImage1.draw(at: CGPoint(x: 0, y: 0))
            processedImage2.draw(at: CGPoint(x: halfWidth, y: 0))
        }

        return diptychImage
    }
}
