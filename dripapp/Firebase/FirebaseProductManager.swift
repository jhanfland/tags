import Foundation
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class FirebaseProductManager: ObservableObject {
    // MARK: - Properties
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    private let openAIManager = OpenAIManager()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    // MARK: - Error Types
    enum StorageError: LocalizedError {
        case authenticationRequired
        case permissionDenied
        case imageProcessingFailed
        case uploadFailed(String)
        case unknown(Error)
        
        var errorDescription: String? {
            switch self {
            case .authenticationRequired:
                return "User authentication required"
            case .permissionDenied:
                return "Permission denied to access storage"
            case .imageProcessingFailed:
                return "Failed to process image"
            case .uploadFailed(let reason):
                return "Upload failed: \(reason)"
            case .unknown(let error):
                return "Unknown error: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                if let userId = user?.uid {
                    print("User authenticated with ID: \(userId)")
                }
            }
        }
    }
    
    
    // Add comment: Replacing local image processing with shared utility
    private func processImage(_ image: UIImage) throws -> Data {
        return try AppUtilities.shared.processImage(image)
    }
    
    // MARK: - Upload Operations
    
    private func uploadImage(_ image: UIImage, productId: String, index: Int) async throws -> URL {
        guard let user = Auth.auth().currentUser else {
            throw StorageError.authenticationRequired
        }
        
        print("Processing image \(index) for product \(productId)")
        let imageData = try processImage(image)
        
        let imagePath = "users/\(user.uid)/products/\(productId)/image_\(index).jpeg"
        let imageRef = storage.child(imagePath)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        print("Uploading image to path: \(imagePath)")
        
        do {
            _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
            let downloadURL = try await imageRef.downloadURL()
            print("Successfully uploaded image \(index) with URL: \(downloadURL)")
            return downloadURL
        } catch {
            print("Failed to upload image: \(error.localizedDescription)")
            throw StorageError.uploadFailed(error.localizedDescription)
        }
    }
    

    func saveProduct(_ product: ItemData) async throws -> ItemData {
        guard let user = Auth.auth().currentUser else {
            throw StorageError.authenticationRequired
        }
        print("Starting product save for user: \(product.userId)")
        
        // Added: Verify userId is not empty
        guard !product.userId.isEmpty else {
            throw StorageError.uploadFailed("User ID is required")
        }
        
        guard let images = product.images, !images.isEmpty else {
            print("Error: No images provided")
            throw StorageError.uploadFailed("No images provided")
        }
        
        do {
            DispatchQueue.main.async { self.isLoading = true }
            defer { DispatchQueue.main.async { self.isLoading = false } }
            
            // Generate a unique ID for the product if it doesn't have one
            var updatedProduct = product
            let productId = product.id ?? UUID().uuidString
            updatedProduct.id = productId
            updatedProduct.userId = user.uid
            
            print("Uploading \(images.count) images")
            
            var imageUrls: [String] = []
            
            try await withThrowingTaskGroup(of: (Int, URL).self) { group in
                for (index, image) in images.enumerated() {
                    group.addTask {
                        let url = try await self.uploadImage(image, productId: productId, index: index)
                        return (index, url)
                    }
                }
                
                var urlDict: [Int: URL] = [:]
                for try await (index, url) in group {
                    urlDict[index] = url
                }
                
                imageUrls = urlDict.sorted(by: { $0.key < $1.key }).map { $0.value.absoluteString }
            }
            
            print("Successfully uploaded all images")
            
            updatedProduct.imageUrls = imageUrls
            
            // Save initial version with original data
            try await saveProductToFirestore(updatedProduct)
            
            // Get AI analysis
            let analyzedProduct = try await openAIManager.generateItemInfo(for: updatedProduct)
            
            // Prepare final version while preserving critical fields
            var finalProduct = analyzedProduct
            finalProduct.id = productId
            finalProduct.userId = product.userId // Ensure userId is preserved
            finalProduct.price = product.price
            finalProduct.imageUrls = imageUrls
            finalProduct.isLoading = false
            
            // Save final version
            try await saveProductToFirestore(finalProduct)
            
            return finalProduct
            
        } catch {
            print("Error saving product: \(error.localizedDescription)")
            throw error
        }
    }
    private func saveProductToFirestore(_ product: ItemData) async throws {
        do {
            let documentRef: DocumentReference
            if let productId = product.id {
                documentRef = db.collection("products").document(productId)
            } else {
                documentRef = db.collection("products").document()
                var productWithId = product
                productWithId.id = documentRef.documentID
                
                // Create a dictionary representation that preserves image URLs
                var productData = try makeFirestoreData(from: productWithId)
                if let imageUrls = productWithId.imageUrls {
                    productData["imageUrls"] = imageUrls
                }
                
                try await documentRef.setData(productData)
                return
            }
            
            // Create a dictionary representation that preserves image URLs
            var productData = try makeFirestoreData(from: product)
            if let imageUrls = product.imageUrls {
                productData["imageUrls"] = imageUrls
            }
            
            try await documentRef.setData(productData)
            print("Successfully saved product to Firestore with ID: \(documentRef.documentID)")
            
        } catch {
            print("Firestore save error: \(error.localizedDescription)")
            throw StorageError.uploadFailed("Failed to save to Firestore: \(error.localizedDescription)")
        }
    }
    private func makeFirestoreData(from product: ItemData) throws -> [String: Any] {
        let encoder = Firestore.Encoder()
        var data = try encoder.encode(product)
        
        // Ensure imageUrls are preserved
        if let imageUrls = product.imageUrls {
            data["imageUrls"] = imageUrls
        }
        
        return data
    }
    
    
    func fetchProducts(for userId: String) async throws -> [ItemData] {
        print("Fetching products for user: \(userId)")
        do {
            let querySnapshot = try await db.collection("products")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            // Comment: Simply decode directly from the document, letting Firestore handle the conversion
            let products = try querySnapshot.documents.compactMap { document in
                try document.data(as: ItemData.self)
            }
            
            print("Successfully fetched \(products.count) products")
            return products
            
        } catch {
            print("Error fetching products: \(error)")
            throw error
        }
    }

    
    func fetchAllProducts() async throws -> [ItemData] {
        print("Fetching all products")
        do {
            let querySnapshot = try await db.collection("products").getDocuments()
            let products = try querySnapshot.documents.compactMap { document in
                try document.data(as: ItemData.self)
            }
            print("Successfully fetched \(products.count) products")
            return products
        } catch {
            print("Error fetching all products: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Product Update
    
    func updateProduct(_ product: ItemData) throws {
        guard let productId = product.id else {
            throw StorageError.uploadFailed("Product ID is missing")
        }
        
        print("Updating product with ID: \(productId)")
        do {
            try db.collection("products").document(productId).setData(from: product)
            print("Successfully updated product")
        } catch {
            print("Error updating product: \(error.localizedDescription)")
            throw error
        }
    }
        
    func deleteProduct(_ productId: String) async throws {
        print("Starting deletion process for product ID: \(productId)")
        
        guard let user = Auth.auth().currentUser else {
            print("Error: No authenticated user")
            throw StorageError.authenticationRequired
        }
        
        print("Authenticated user ID: \(user.uid)")
        
        do {
            // First verify the product exists and belongs to the user
            let document = try await db.collection("products").document(productId).getDocument()
            
            guard document.exists else {
                print("Error: Document \(productId) does not exist")
                throw StorageError.uploadFailed("Document does not exist")
            }
            
            guard let userId = document.get("userId") as? String else {
                print("Error: Document has no userId field")
                throw StorageError.uploadFailed("Document has no userId")
            }
            
            guard userId == user.uid else {
                print("Error: Document belongs to different user")
                throw StorageError.permissionDenied
            }
            
            print("Verified document ownership, proceeding with deletion")
            try await db.collection("products").document(productId).delete()
            print("Successfully deleted document from Firestore")
            let imagesRef = storage.child("users/\(user.uid)/products/\(productId)")
            do {
                print("Attempting to delete associated images")
                let listResult = try await imagesRef.listAll()
                
                if listResult.items.isEmpty {
                    print("No images found to delete")
                } else {
                    print("Found \(listResult.items.count) images to delete")
                }
                
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for item in listResult.items {
                        group.addTask {
                            print("Deleting image: \(item.name)")
                            try await item.delete()
                        }
                    }
                    try await group.waitForAll()
                }
                print("Successfully deleted all associated images")
            } catch {
                print("Warning: Error deleting images: \(error.localizedDescription)")
            }
            
            print("Product deletion completed successfully")
        } catch {
            print("Error in deletion process: \(error.localizedDescription)")
            throw error
        }
    }
}
