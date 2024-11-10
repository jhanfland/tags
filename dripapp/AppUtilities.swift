import SwiftUI
import UIKit
import Firebase
import FirebaseStorage
import Kingfisher

// Add comment: Core utilities class containing commonly used functions across the app
class AppUtilities {
    static let shared = AppUtilities()
        func processImage(_ image: UIImage, maxSize: CGFloat = 1024) throws -> Data {
        let scale = min(maxSize / image.size.width, maxSize / image.size.height)
        
        let processedImage: UIImage
        if scale < 1 {
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            defer { UIGraphicsEndImageContext() }
            
            image.draw(in: CGRect(origin: .zero, size: newSize))
            guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext() else {
                throw ImageError.processingFailed
            }
            processedImage = resizedImage
        } else {
            processedImage = image
        }
        
        guard let imageData = processedImage.jpegData(compressionQuality: 0.8) else {
            throw ImageError.compressionFailed
        }
        
        return imageData
    }
    
    func formatPrice(_ price: String) -> String {
        guard let value = Double(price) else { return "$0.00" }
        return String(format: "$%.2f", value)
    }
    
    func getSizesForCategory(_ category: String) -> [String] {
        switch category {
        case "Tops", "Shirts", "Outerwear", "Swimwear", "Dresses", "Pullovers", "Jackets":
            return CategoryData.topSizes
        case "Bottoms":
            return CategoryData.bottomSizes
        case "Shoes":
            return CategoryData.shoeSizes
        default:
            return []
        }
    }
    
    func formatAddress(_ address: AddressSuggestion) -> String {
        return "\(address.streetNumber) \(address.streetName)\n\(address.city), \(address.state) \(address.zipCode)"
    }
    
    // Add comment: Shared error handling with unified presentation
    func showError(_ message: String, in view: UIView) {
        DispatchQueue.main.async {
            // Add your preferred error presentation method
            print("Error: \(message)")
            // You could also implement a custom toast or alert here
        }
    }
    // Centralized filter management methods
        func isFilterActive(_ category: String, in criteria: SearchCriteria) -> Bool {
            switch category {
            case "Category": return criteria.selectedCategory != nil
            case "Subcategory": return !criteria.selectedSubcategories.isEmpty
            case "Brand": return !criteria.selectedBrands.isEmpty
            case "Condition": return !criteria.selectedConditions.isEmpty
            case "Color": return !criteria.selectedColors.isEmpty
            case "Source": return !criteria.selectedSources.isEmpty
            case "Age": return !criteria.selectedAges.isEmpty
            case "Style": return !criteria.selectedStyles.isEmpty
            case "Size": return !criteria.selectedTopSizes.isEmpty ||
                               !criteria.selectedBottomSizes.isEmpty ||
                               !criteria.selectedShoeSizes.isEmpty
            default: return false
            }
        }
        
        func getOptionsForCategory(_ category: String, searchCriteria: SearchCriteria) -> [String] {
            switch category {
            case "Category":
                return searchCriteria.selectedGender == .mens ?
                       CategoryData.mensSearchCategories.map { $0.0 } :
                       CategoryData.womensSearchCategories.map { $0.0 }
            case "Subcategory":
                return CategoryData.subcategoriesFor(
                    category: searchCriteria.selectedCategory ?? "",
                    gender: searchCriteria.selectedGender
                )
            case "Size":
                return getSizesForCategory(searchCriteria.selectedCategory ?? "")
            default:
                return CategoryData.optionsForCategory(category)
            }
        }
        
        func handleFilterSelection(
            category: String,
            option: String,
            searchCriteria: inout SearchCriteria,
            expandedCategory: inout String?
        ) {
            switch category {
            case "Category":
                searchCriteria.selectedCategory = option
                searchCriteria.selectedSubcategories.removeAll()
                searchCriteria.selectedTopSizes.removeAll()
                searchCriteria.selectedBottomSizes.removeAll()
                searchCriteria.selectedShoeSizes.removeAll()
                expandedCategory = "Subcategory"
            case "Size":
                handleSizeSelection(for: searchCriteria.selectedCategory ?? "",
                                  size: option,
                                  searchCriteria: &searchCriteria)
            default:
                toggleSelection(for: category, option: option, searchCriteria: &searchCriteria)
            }
        }
        
        func getSelectedOptionsForCategory(_ category: String, from criteria: SearchCriteria) -> Set<String> {
            switch category {
            case "Category":
                return criteria.selectedCategory != nil ? [criteria.selectedCategory!] : []
            case "Subcategory":
                return criteria.selectedSubcategories
            case "Brand":
                return criteria.selectedBrands
            case "Condition":
                return criteria.selectedConditions
            case "Color":
                return criteria.selectedColors
            case "Source":
                return criteria.selectedSources
            case "Age":
                return criteria.selectedAges
            case "Style":
                return criteria.selectedStyles
            case "Size":
                return criteria.selectedTopSizes.union(criteria.selectedBottomSizes).union(criteria.selectedShoeSizes)
            default:
                return []
            }
        }
        
        private func toggleSelection(for category: String,
                                   option: String,
                                   searchCriteria: inout SearchCriteria) {
            switch category {
            case "Subcategory": toggleSet(&searchCriteria.selectedSubcategories, option)
            case "Brand": toggleSet(&searchCriteria.selectedBrands, option)
            case "Condition": toggleSet(&searchCriteria.selectedConditions, option)
            case "Color": toggleSet(&searchCriteria.selectedColors, option)
            case "Source": toggleSet(&searchCriteria.selectedSources, option)
            case "Age": toggleSet(&searchCriteria.selectedAges, option)
            case "Style": toggleSet(&searchCriteria.selectedStyles, option)
            default: break
            }
        }
        
        private func toggleSet(_ set: inout Set<String>, _ option: String) {
            if set.contains(option) {
                set.remove(option)
            } else {
                set.insert(option)
            }
        }
        
        func handleSizeSelection(for category: String, size: String, searchCriteria: inout SearchCriteria) {
            switch category {
            case "Tops", "Shirts", "Outerwear", "Swimwear", "Dresses", "Pullovers", "Jackets":
                toggleSet(&searchCriteria.selectedTopSizes, size)
            case "Bottoms":
                toggleSet(&searchCriteria.selectedBottomSizes, size)
            case "Shoes":
                toggleSet(&searchCriteria.selectedShoeSizes, size)
            default:
                break
            }
        }
    
    // Add comment: Shared image uploading logic
    func uploadImage(_ image: UIImage, to path: String) async throws -> URL {
        guard let imageData = try? processImage(image) else {
            throw ImageError.processingFailed
        }
        
        let storageRef = Storage.storage().reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            let downloadURL = try await storageRef.downloadURL()
            return downloadURL
        } catch {
            throw ImageError.uploadFailed(error.localizedDescription)
        }
    }
    
    // Add comment: Shared image carousel view component
    func imageCarouselView(urls: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(urls, id: \.self) { urlString in
                    if let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: UIScreen.main.bounds.width * 0.8, height: 300)
                                .clipped()
                                .cornerRadius(10)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// Add comment: Custom error types for image handling
enum ImageError: Error {
    case processingFailed
    case compressionFailed
    case uploadFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .processingFailed:
            return "Failed to process image"
        case .compressionFailed:
            return "Failed to compress image"
        case .uploadFailed(let reason):
            return "Failed to upload image: \(reason)"
        }
    }
}

// Add comment: Reusable validation protocols
protocol DataValidation {
    func validatePrice(_ price: String) -> Bool
    func validateSize(_ size: String, for category: String) -> Bool
}

extension AppUtilities: DataValidation {
    func validatePrice(_ price: String) -> Bool {
        guard let value = Double(price) else { return false }
        return value > 0
    }
    
    func validateSize(_ size: String, for category: String) -> Bool {
        let validSizes = getSizesForCategory(category)
        return validSizes.contains(size)
    }
}


// Add comment: Shared image picker component
struct SharedImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: SharedImagePicker
        
        init(_ parent: SharedImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
struct SharedFilterButton: View {
    let title: String
    let isSelected: Bool
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundColor(isSelected ? .white : .black)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(10)
        }
    }
}
// Add comment: Shared image grid component

// Add comment: Shared modern price input view
struct SharedPriceInput: View {
    @Binding var price: String
    @Binding var parcelSize: String
    @FocusState.Binding var isFocused: Bool
    
    let sizes = ["XS", "S", "M", "L", "XL"]
    let descriptions = [
        "<8oz - Swimwear, small tops",
        "<12oz - Tops, t-shirts, pants",
        "<16oz - Jeans, lightweight jumpers",
        "<2lb - Hoodies, light jackets, sneakers",
        "<10lb - Bundles, large accessories"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            parcelSizeSelector
            priceInput
        }
    }
    
    // Add comment: Fixed description lookup in SharedPriceInput
    private var parcelSizeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Parcel Size")
                .font(.headline)
                .foregroundColor(.gray)
            
            HStack {
                ForEach(sizes, id: \.self) { size in
                    sizeButton(for: size)
                }
            }
            
            // Fixed optional binding
            if let index = sizes.firstIndex(of: parcelSize),
               index < descriptions.count {
                Text(descriptions[index])
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 8)
            }
        }
    }
    
    private var priceInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Set Your Price")
                .font(.headline)
                .foregroundColor(.gray)
            
            HStack {
                Text("$")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.green)
                    .padding(.leading, 16)
                
                TextField("0", text: $price)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.green)
                    .keyboardType(.numberPad)
                    .focused($isFocused)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.green.opacity(0.1))
            .cornerRadius(15)
        }
    }
    
    private func sizeButton(for size: String) -> some View {
        Button(action: { parcelSize = size }) {
            Text(size)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(parcelSize == size ? .white : .blue)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(parcelSize == size ? Color.blue : Color.blue.opacity(0.1))
                .cornerRadius(12)
        }
    }
}

struct SharedButtonStyles {
    static func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(15)
        }
    }
    
    static func secondaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(15)
        }
    }
}
// Add comment: Keyboard awareness modifier for views
struct KeyboardAwareModifier: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onAppear {
                setupKeyboardNotifications()
            }
            .onDisappear {
                removeKeyboardNotifications()
            }
    }
    
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            keyboardHeight = keyboardFrame.height
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            keyboardHeight = 0
        }
    }
    
    private func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}
// Add comment: Additional shared components for item display
struct SharedItemImage: View {
    let url: String?
    
    var body: some View {
        if let urlString = url, let url = URL(string: urlString) {
            KFImage(url)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .cornerRadius(8)
        } else {
            Color.gray
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .cornerRadius(8)
        }
    }
}

struct SharedItemDetails: View {
    let item: ItemData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.isLoading ? "Loading..." : item.description.capitalized)
                .font(.system(size: 14, weight: .bold))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if item.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    .scaleEffect(0.7)
            } else {
                SharedItemStats(item: item)
            }
        }
    }
}

struct SharedItemStats: View {
    let item: ItemData
    
    var body: some View {
        HStack {
            SharedStatColumn(title: "Price", value: "$\(item.price ?? "")")
            Spacer()
            SharedStatColumn(title: "Category", value: item.category)
            Spacer()
            SharedStatColumn(title: "Size", value: item.size)
            Spacer()
            SharedStatColumn(title: "Brand", value: item.brand)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SharedStatColumn: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
            Text(value)
                .font(.caption.bold())
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

struct SharedButtonStyle: ButtonStyle {
    let foregroundColor: Color
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let shadow: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: shadow ? Color.black.opacity(0.2) : .clear,
                   radius: 5, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

struct SharedItemView: View {
    let item: ItemData
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SharedImageGallery(urls: item.imageUrls ?? [])
                itemDescription
                itemDetails
            }
            .padding()
        }
        .navigationTitle("Item Details")
    }
    
    private var itemDescription: some View {
        Text(item.description)
            .font(.system(size: 16))
    }
    
    private var itemDetails: some View {
        VStack(alignment: .leading, spacing: 10) {
            SharedDetailRow(title: "Gender", value: item.gender)
            SharedDetailRow(title: "Price", value: AppUtilities.shared.formatPrice(item.price ?? "0"))
            SharedDetailRow(title: "Category", value: item.category)
            SharedDetailRow(title: "Subcategory", value: item.subcategory)
            SharedDetailRow(title: "Brand", value: item.brand)
            SharedDetailRow(title: "Condition", value: item.condition)
            SharedDetailRow(title: "Size", value: item.size)
            SharedDetailRow(title: "Color", value: item.color)
            SharedDetailRow(title: "Source", value: item.source)
            SharedDetailRow(title: "Age", value: item.age)
            SharedDetailRow(title: "Style", value: item.style.joined(separator: ", "))
            SharedDetailRow(title: "Parcel Size", value: item.parcelSize)
        }
    }
}

struct SharedDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Text(value)
                .font(.body)
        }
    }
}

struct SharedImageGallery: View {
    let urls: [String]
    let height: CGFloat = 200
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(urls, id: \.self) { urlString in
                    SharedGalleryImage(urlString: urlString, height: height)
                }
            }
        }
    }
}

// Add comment: Shared gallery image component
struct SharedGalleryImage: View {
    let urlString: String
    let height: CGFloat
    
    var body: some View {
        KFImage(URL(string: urlString))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: height)
    }
}

struct ItemPopupView: View {
    @Binding var item: ItemData
    @Binding var isPresented: Bool
    var onUpdate: (ItemData) -> Void
    
    @State private var editedItem: ItemData
    @State private var selectedCategory: String?
    @FocusState private var isPriceFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    init(item: Binding<ItemData>, isPresented: Binding<Bool>, onUpdate: @escaping (ItemData) -> Void) {
        self._item = item
        self._isPresented = isPresented
        self.onUpdate = onUpdate
        self._editedItem = State(initialValue: item.wrappedValue)
    }
    
    var body: some View {
        SharedItemView(item: editedItem)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Update") {
                        onUpdate(editedItem)
                        dismiss()
                    }
                }
            }
    }
}
// Add comment: Shared instructions view
struct SharedInstructionsView: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(15)
    }
}
// Add comment: Added missing Array extension for chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

// Add comment: Added missing ImageCarouselView component
struct ImageCarouselView: View {
    let imageUrls: [String]?
    let height: CGFloat
    let width: CGFloat
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(imageUrls ?? [], id: \.self) { urlString in
                    if let url = URL(string: urlString) {
                        KFImage(url)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: width, height: height)
                            .clipped()
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: height)
    }
}

// Add comment: Added missing MessageInput component
struct MessageInput: View {
    @Binding var isShowing: Bool
    @Binding var messageText: String
    let onSend: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack {
            Spacer()
            VStack {
                TextField("Type your message...", text: $messageText)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 5)
                    .focused($isTextFieldFocused)
                
                HStack {
                    Button("Cancel") {
                        isShowing = false
                    }
                    Spacer()
                    Button("Send") {
                        onSend()
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(20)
            .padding()
        }
        .transition(.move(edge: .bottom))
        .animation(.spring(), value: isShowing)
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
}

struct PaymentButton: View {
    let title: String
    var icon: String? = nil
    var imageName: String? = nil
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 24)
                } else if let imageName = imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 24)
                }
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: 5)
        }
        .frame(height: 55)
    }
}
// Add comment: Extension to make the modifier easier to use
extension View {
    func keyboardAware() -> some View {
        modifier(KeyboardAwareModifier())
    }
}
