import Foundation

struct CategoryData {
    static let brands = ["Nike", "Adidas", "Levi's", "Liquid Blue", "Zara"]
    static let conditions = ["Brand new", "Used - Excellent", "Used - Good", "Used - Fair"]
    static let colors = ["Black", "White", "Gray", "Navy", "Blue", "Red", "Green", "Yellow", "Pink", "Purple", "Orange", "Brown", "Beige", "Cream", "Gold", "Silver", "Multi"]
    static let sources = ["Vintage", "Custom", "Brand New", "Designer", "Handmade", "Modern"]
    static let ages = ["Modern", "Y2K", "00s", "90s", "80s", "70s", "60s", "50s", "Antique"]
    static let styles = ["Streetwear", "Sportswear", "Loungewear", "Formal", "Casual", "Bohemian", "Vintage", "Preppy", "Gothic", "Punk", "Retro", "Minimalist", "Grunge", "Hipster", "Chic", "Classic", "Edgy", "Athleisure", "Boho", "Glamorous", "Elegant", "Trendy", "Alternative", "Artistic", "Business", "Cyberpunk", "Eclectic", "Hip-hop", "Indie", "Skater", "Surfer", "Western"]

    static let mensSubcategories = [
        "Shirts": ["T-shirts", "Dress shirts", "Polo shirts"],
        "Jackets": ["Light jackets", "Heavy jackets", "Denim jackets", "Leather Jackets"],
        "Bottoms": ["Jeans", "Casual trousers", "Shorts", "Sweatpants"],
        "Pullovers": ["Hoodies", "Crewnecks", "Zip-Up", "Fleeces", "Sweaters"],
        "Shoes": ["Sneakers", "Boots", "Dress shoes"],
        "Hats": ["Baseball caps", "Beanies", "Other"],
        "Accessories": ["Glasses", "Watches", "Other"]
    ]

    static let womensSubcategories = [
        "Tops": ["Blouses", "T-shirts", "Tank tops"],
        "Bottoms": ["Jeans", "Skirts", "Shorts"],
        "Swimwear": ["Bikinis", "One-pieces", "Cover-ups"],
        "Dresses": ["Casual dresses", "Formal dresses", "Sundresses"],
        "Outerwear": ["Jackets", "Coats", "Cardigans"],
        "Shoes": ["Heels", "Flats", "Sneakers"],
        "Accessories": ["Jewelry", "Bags", "Scarves"]
    ]

    static let topSizes = ["XS", "S", "M", "L", "XL", "XXL"]
    static let bottomSizes = ["28", "30", "32", "34", "36", "38", "40"]
    static let shoeSizes = ["6", "7", "8", "9", "10", "11", "12", "13"]

    static let mensCategories = [
        ("For You", "sparkles"),
        ("Shirts", "tshirt"),
        ("Jackets", "jacket"),
        ("Bottoms", "pants"),
        ("Pullovers", "sweatshirt"),
        ("Shoes", "shoe"),
        ("Hats", "hat.cap"),
        ("Accessories", "accessories")
    ]

    static let womensCategories = [
        ("For You", "sparkles"),
        ("Tops", "blouse"),
        ("Bottoms", "jean_shorts"),
        ("Swimwear", "swim"),
        ("Dresses", "dress"),
        ("Outerwear", "outerwear"),
        ("Shoes", "shoe"),
        ("Accessories", "accessories")
    ]
    static let mensSearchCategories = [
        ("Shirts", "tshirt"),
        ("Jackets", "jacket"),
        ("Bottoms", "pants"),
        ("Pullovers", "sweatshirt"),
        ("Shoes", "shoe"),
        ("Hats", "hat.cap"),
        ("Accessories", "accessories")
    ]

    static let womensSearchCategories = [
        ("Tops", "blouse"),
        ("Bottoms", "jean_shorts"),
        ("Swimwear", "swim"),
        ("Dresses", "dress"),
        ("Outerwear", "outerwear"),
        ("Shoes", "shoe"),
        ("Accessories", "accessories")
    ]
    
    

    static func subcategoriesFor(category: String, gender: SearchView.Gender) -> [String] {
        let subcategories = gender == .mens ? mensSubcategories : womensSubcategories
        return subcategories[category] ?? []
    }

    static let filterCategories = ["Category", "Subcategory", "Brand", "Condition", "Size", "Color", "Source", "Age", "Style"]

    static func optionsForCategory(_ category: String) -> [String] {
        switch category {
        case "Brand":
            return brands
        case "Condition":
            return conditions
        case "Color":
            return colors
        case "Source":
            return sources
        case "Age":
            return ages
        case "Style":
            return styles
        case "Parcel Size":
            return ["S", "M", "L"]
        default:
            return []
        }
    }

    static func sizesForCategory(_ category: String) -> [String] {
        switch category {
        case "Tops", "Shirts", "Outerwear", "Dresses", "Swimwear", "Pullovers", "Jackets":
            return topSizes
        case "Bottoms":
            return bottomSizes
        case "Shoes":
            return shoeSizes
        default:
            return topSizes + bottomSizes + shoeSizes
        }
    }
}
