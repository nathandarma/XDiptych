import SwiftUI
import PhotosUI

struct AdjustableImage: Identifiable {
    let id = UUID()
    var image: UIImage? = nil
    var photosItem: PhotosPickerItem? = nil
    var scale: CGFloat = 1.0
    var offset: CGSize = .zero
}
