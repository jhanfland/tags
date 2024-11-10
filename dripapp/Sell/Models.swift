import Foundation
import FirebaseFirestore

struct ItemData: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var description: String
    var gender: String
    var category: String
    var subcategory: String
    var brand: String
    var condition: String
    var size: String
    var color: String
    var source: String
    var age: String
    var style: [String]
    var parcelSize: String
    var price: String?
    var imageUrls: [String]?
    var isLoading: Bool
    var images: [UIImage]?

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case description = "Description"
        case gender = "Gender"
        case category = "Category"
        case subcategory = "Subcategory"
        case brand = "Brand"
        case condition = "Condition"
        case size = "Size"
        case color = "Color"
        case source = "Source"
        case age = "Age"
        case style = "Style"
        case parcelSize = "ParcelSize"
        case price
        case imageUrls
        case isLoading
    }
    
    static func placeholder() -> ItemData {
        return ItemData(
            id: nil,
            userId: "placeholderUser",
            description: "Sample description",
            gender: "Men's",
            category: "Shirts",
            subcategory: "T-Shirts",
            brand: "Nike",
            condition: "Used - Excellent",
            size: "M",
            color: "White",
            source: "Stitched",
            age: "Modern",
            style: ["Casual"],
            parcelSize: "S",
            price: "29.99",
            imageUrls: nil,
            isLoading: false
        )
    }
}
