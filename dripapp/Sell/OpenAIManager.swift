import Foundation
import UIKit

class OpenAIManager: ObservableObject {
    // MARK: - Properties
    // Added comment: Using environment variable or secure storage recommended for API key
    private let apiKey = "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"
    // Added comment: Updated to latest OpenAI API endpoint
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    @Published var itemData: ItemData?
    
    // MARK: - Error Handling
    enum OpenAIError: Error {
        case invalidURL
        case noImageURLs
        case invalidResponseStructure
        case noFunctionCall
        case decodingError(String)
        case apiError(String)  // Added: New error case for API-specific errors
    }
    
    // MARK: - OpenAI Response Struct
    struct OpenAIItemData: Codable {
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
        
        enum CodingKeys: String, CodingKey {
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
        }
    }
    func generateItemInfo(for item: ItemData) async throws -> ItemData {
        print("Starting to generate item information for product")
        
        guard let imageUrls = item.imageUrls, !imageUrls.isEmpty else {
            print("Error: No image URLs provided")
            throw OpenAIError.noImageURLs
        }
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": "Analyze these images and provide details about the clothing item."],
                        ["type": "image_url", "image_url": ["url": imageUrls[0]]]
                    ]
                ]
            ],
            "tools": [[
                "type": "function",  // Changed from "json_schema" to "function"
                "function": [
                    "name": "itemize_clothing",
                    "description": "Describe the item of clothing from the image focusing on unique and identifiying attributes. Any graphics, writing, logos, and defining characteristic must be included. Use keywords that user's would associate with the item. This should be about 3-4 sentences.",
                    "parameters": [
                        "type": "object",
                        "properties": [
                            "Description": ["type": "string", "description": "A brief but detailed, SEO-friendly description of the clothing item"],
                            "Gender": ["type": "string", "enum": ["Men's", "Women's"]],
                            "Category": ["type": "string", "enum": ["Tops", "Bottoms", "Outerwear", "Dresses", "Swimwear", "Shoes", "Accessories"]],
                            "Subcategory": ["type": "string", "enum": [
                                "T-shirts", "Dress shirts", "Polo shirts", "Tank tops", "Blouses",
                                "Hoodies", "Sweatshirts", "Sweaters", "Cardigans", "Pullovers",
                                "Jeans", "Casual trousers", "Dress trousers", "Shorts", "Skirts",
                                "Jackets", "Coats", "Blazers", "Vests",
                                "Casual dresses", "Formal dresses", "Sundresses",
                                "Bikinis", "One-pieces", "Cover-ups",
                                "Sneakers", "Boots", "Dress shoes", "Heels", "Flats",
                                "Hats", "Belts", "Scarves", "Jewelry", "Bags", "Sunglasses", "Watches"
                            ]],
                            "Brand": ["type": "string"],
                            "Condition": ["type": "string", "enum": ["Brand new", "Used - Excellent", "Used - Good", "Used - Fair"]],
                            "Size": ["type": "string", "enum": [
                                "XS", "S", "M", "L", "XL", "XXL",
                                "28", "30", "32", "34", "36", "38", "40",
                                "6", "7", "8", "9", "10", "11", "12", "13"
                            ]],
                            "Color": ["type": "string", "enum": ["Black", "White", "Gray", "Navy", "Blue", "Red", "Green", "Yellow", "Pink", "Purple", "Orange", "Brown", "Beige", "Cream", "Gold", "Silver", "Tie-Dye"]],
                            "Source": ["type": "string", "enum": ["Stitched", "Printed", "No Tag"]],
                            "Age": ["type": "string", "enum": ["Modern", "Y2K", "90s", "80s", "70s", "60s", "50s", "Antique"]],
                            "Style": ["type": "array", "items": ["type": "string", "enum": [
                                "Streetwear", "Sportswear", "Loungewear", "Formal", "Casual", "Vintage",
                                "Preppy", "Gothic", "Punk", "Retro", "Minimalist", "Grunge",
                                "Classic", "Edgy", "Athleisure", "Glamorous", "Elegant", "Trendy",
                                "Alternative", "Artistic", "Business",
                                "Hip-hop", "Indie", "Skater"
                            ]]]
                        ],
                        "required": ["Description", "Gender", "Category", "Subcategory", "Brand", "Condition", "Size", "Color", "Source", "Age", "Style"]
                    ]
                ]
            ]],
            "tool_choice": [
                "type": "function",
                "function": ["name": "itemize_clothing"]
            ]
        ]
        
        return try await performOpenAIRequest(with: requestBody, existingItem: item)
    }
   
    private func performOpenAIRequest(with body: [String: Any], existingItem: ItemData) async throws -> ItemData {
        guard let url = URL(string: baseURL) else {
            print("Error: Invalid URL")
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30 // Add timeout
        
        // Print request details for debugging
        print("Making request to OpenAI API...")
        print("URL: \(url)")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
            
            // Print request body for debugging
            if let requestStr = String(data: jsonData, encoding: .utf8) {
                print("Request body: \(requestStr)")
            }
        } catch {
            print("Error serializing request body: \(error)")
            throw OpenAIError.invalidResponseStructure
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Print response details for debugging
            print("Received response from OpenAI API")
            print("Response status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            if let responseStr = String(data: data, encoding: .utf8) {
                print("Response body: \(responseStr)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Error: Invalid Response structure")
                throw OpenAIError.invalidResponseStructure
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorJson["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    print("OpenAI API error: \(message)")
                    throw OpenAIError.apiError(message)
                } else {
                    let errorMessage = "Request failed with status code \(httpResponse.statusCode)"
                    print(errorMessage)
                    throw OpenAIError.apiError(errorMessage)
                }
            }
            
            return try handleOpenAIResponse(data: data, existingItem: existingItem)
            
        } catch let error as OpenAIError {
            print("OpenAI specific error: \(error)")
            throw error
        } catch {
            print("Network or other error: \(error)")
            throw OpenAIError.apiError(error.localizedDescription)
        }
    }
    
    private func handleOpenAIResponse(data: Data, existingItem: ItemData) throws -> ItemData {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let toolCalls = message["tool_calls"] as? [[String: Any]],
              let firstToolCall = toolCalls.first,
              let function = firstToolCall["function"] as? [String: Any],
              let argumentsString = function["arguments"] as? String else {
            throw OpenAIError.invalidResponseStructure
        }
        
        return try decodeItemData(from: argumentsString, existingItem: existingItem)
    }
                                                                                                                                                                                                           
    private func decodeItemData(from argumentsString: String, existingItem: ItemData) throws -> ItemData {
        guard let argumentsData = argumentsString.data(using: .utf8) else {
            throw OpenAIError.decodingError("Failed to convert arguments string to data")
        }
        
        do {
            let decoder = JSONDecoder()
            let aiItemData = try decoder.decode(OpenAIItemData.self, from: argumentsData)
            
            var updatedItem = existingItem
            updatedItem.description = aiItemData.description
            updatedItem.gender = aiItemData.gender
            updatedItem.category = aiItemData.category
            updatedItem.subcategory = aiItemData.subcategory
            updatedItem.brand = aiItemData.brand
            updatedItem.condition = aiItemData.condition
            updatedItem.size = aiItemData.size
            updatedItem.color = aiItemData.color
            updatedItem.source = aiItemData.source
            updatedItem.age = aiItemData.age
            updatedItem.style = aiItemData.style
            
            return updatedItem
        } catch {
            throw OpenAIError.decodingError(error.localizedDescription)
        }
    }
    func extractKeywords(from searchText: String) async throws -> [String] {
            let prompt = "Extract concise keywords from the following search query: \"\(searchText)\""
            let requestBody: [String: Any] = [
                "model": "gpt-4o",
                "prompt": prompt,
                "temperature": 0.0
            ]
            
            let data = try await performRequest(with: requestBody)
            guard let keywordsText = parseKeywordsResponse(data: data) else {
                throw OpenAIError.apiError("Failed to parse keywords")
            }
            
            // Split keywords by commas and trim whitespace
            let keywords = keywordsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            return keywords
        }
        
        // MARK: - Perform Request
        private func performRequest(with requestBody: [String: Any]) async throws -> Data {
            guard let url = URL(string: baseURL) else {
                throw OpenAIError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorJson["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw OpenAIError.apiError(message)
                } else {
                    throw OpenAIError.apiError("Request failed with status code \(response as? HTTPURLResponse)?.statusCode ?? 0)")
                }
            }
            
            return data
        }
        
        // MARK: - Parse Keywords Response
        private func parseKeywordsResponse(data: Data) -> String? {
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let text = firstChoice["text"] as? String else {
                return nil
            }
            
            return text
        }
}
