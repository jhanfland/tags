// Add comment: Simplified AddClothesView using shared components
import SwiftUI

// Add comment: Fixed AddClothesView implementation
import SwiftUI

struct AddClothesView: View {
    @StateObject private var viewModel: AddClothesViewModel
    @Environment(\.dismiss) var dismiss
    @FocusState private var isPriceFieldFocused: Bool
    
    let onSave: (Result<ItemData, Error>) -> Void
    
    init(onSave: @escaping (Result<ItemData, Error>) -> Void, userId: String) {
        self.onSave = onSave
        self._viewModel = StateObject(wrappedValue: AddClothesViewModel(userId: userId))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            addImageGrid(
                                images: $viewModel.uploadedImages,
                                imageLabels: viewModel.imageLabels,
                                currentIndex: $viewModel.currentImageIndex,
                                showImagePicker: $viewModel.showImagePicker,
                                onImageTap: { index in
                                    viewModel.showImageOptions()
                                }
                            )
                            .frame(height: 270)
                            .padding(.top)
                            
                            SharedPriceInput(
                                price: $viewModel.clothesPrice,
                                parcelSize: $viewModel.parcelSize,
                                isFocused: $isPriceFieldFocused
                            )
                            .padding(.horizontal)
                            
                            Button(action: createItem) {
                                Text("List Item")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(15)
                            }
                            .padding(.horizontal)
                            .disabled(!viewModel.canCreateItem)
                        }
                    }
                    .keyboardAware()
                }
            }
            .navigationTitle("New Listing")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showImagePicker) {
                SharedImagePicker(
                    image: $viewModel.uploadedImages[viewModel.currentImageIndex],
                    sourceType: viewModel.imagePickerSourceType
                )
            }
            .confirmationDialog(
                "Choose Photo Source",
                isPresented: $viewModel.showingImageOptions,
                titleVisibility: .visible
            ) {
                Button("Take Photo") { viewModel.takePhoto() }
                Button("Choose from Library") { viewModel.chooseFromLibrary() }
            }
        }
    }
    
    private func createItem() {
            Task {
                do {
                    // Create initial item in loading state
                    var initialItem = try await viewModel.createAndSaveItem()
                    initialItem.isLoading = true
                    onSave(.success(initialItem))
                    dismiss()
                } catch {
                    onSave(.failure(error))
                }
            }
        }
}

// Add comment: Updated ViewModel with simplified logic
class AddClothesViewModel: ObservableObject {
    @Published var clothesPrice = ""
    @Published var parcelSize = "S"
    @Published var uploadedImages: [UIImage?] = [nil, nil, nil, nil]
    @Published var currentImageIndex = 0
    @Published var showImagePicker = false
    @Published var showingImageOptions = false
    @Published var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    
    let userId: String
    let imageLabels = ["Front", "Tag", "Back", "Graphic, Flaw, etc."]
    
    private let firebaseManager = FirebaseProductManager()
    
    init(userId: String) {
        self.userId = userId
    }
    
    var canCreateItem: Bool {
        !uploadedImages.compactMap({ $0 }).isEmpty && !clothesPrice.isEmpty
    }
    
    func showImageOptions() {
        showingImageOptions = true
    }
    
    func takePhoto() {
        imagePickerSourceType = .camera
        showImagePicker = true
    }
    
    func chooseFromLibrary() {
        imagePickerSourceType = .photoLibrary
        showImagePicker = true
    }
    
    func createAndSaveItem() async throws -> ItemData {
        let validImages = uploadedImages.compactMap { $0 }
        guard !validImages.isEmpty else {
            throw ItemError.noImages
        }
        
        return ItemData(
            id: UUID().uuidString,
            userId: userId,
            description: "",
            gender: "",
            category: "",
            subcategory: "",
            brand: "",
            condition: "",
            size: "",
            color: "",
            source: "",
            age: "",
            style: [],
            parcelSize: parcelSize,
            price: clothesPrice,
            imageUrls: nil,
            isLoading: true,
            images: validImages
        )
    }
}
enum ItemError: LocalizedError {
    case noImages
    
    var errorDescription: String? {
        switch self {
        case .noImages:
            return "At least one image is required"
        }
    }
}
struct addImageGrid: View {
    @Binding var images: [UIImage?]
    let imageLabels: [String]
    @Binding var currentIndex: Int
    @Binding var showImagePicker: Bool
    var onImageTap: (Int) -> Void
    
    private let imageWidth: CGFloat = UIScreen.main.bounds.width * 0.6
    private let spacing: CGFloat = 10
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
                    HStack(spacing: spacing) {
                        ForEach(0..<4) { index in
                            imageBox(for: index)
                                .frame(width: imageWidth)
                                .padding(.vertical, 10)
                                .id(index)
                        }
                    }
                    .padding(.horizontal, geometry.size.width * 0.05)
                    .onChange(of: images) { _, _ in
                        if let nextEmpty = images.firstIndex(where: { $0 == nil }) {
                            withAnimation {
                                proxy.scrollTo(nextEmpty, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .frame(height: 300)
    }
    
    private func imageBox(for index: Int) -> some View {
        ZStack {
            if let image = images[index] {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: imageWidth, height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                emptyImageBox(index: index)
            }
        }
        .onTapGesture {
            currentIndex = index
            onImageTap(index)
        }
    }
    
    private func emptyImageBox(index: Int) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray.opacity(0.2))
            .frame(width: imageWidth, height: 280)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "plus")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.gray.opacity(0.4))
                        .frame(width: 60, height: 60)
                    
                    Text(imageLabels[index])
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text(imageInstructionFor(index: index))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 5)
                }
            )
    }
    
    private func imageInstructionFor(index: Int) -> String {
        switch index {
        case 0: return "Make sure the item fills the frame"
        case 1: return "Ensure it's clear and close-up"
        case 2: return "Include all identifying features"
        case 3: return "Clear and fill the frame"
        default: return ""
        }
    }
}
