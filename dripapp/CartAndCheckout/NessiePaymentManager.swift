import Foundation

// Added comment: Updated NessiePaymentManager with improved error handling and response validation
class NessiePaymentManager {
    static let shared = NessiePaymentManager()
    private let apiKey = "84f3ca014fca8e0f3b24488da4fe1192"
    private let baseURL = "http://api.nessieisreal.com"
    
    // Added comment: Custom errors for better error handling
    enum NessieError: LocalizedError {
        case invalidURL
        case invalidResponse
        case serverError(Int)
        case networkError(Error)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid API URL"
            case .invalidResponse:
                return "Invalid response from server"
            case .serverError(let code):
                return "Server error with code: \(code)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            }
        }
    }
    
    // Added comment: Updated process payment function with better error handling
    func processPayment(fromAccount: String, toAccount: String, amount: Double) async throws -> Bool {
        // Validate account balance
        guard try await checkBalance(forAccount: fromAccount, amount: amount) else {
            throw PaymentError.insufficientFunds
        }
        
        // Process transfer
        return try await performTransfer(fromAccount: fromAccount, toAccount: toAccount, amount: amount)
    }
    
    // Added comment: New helper function to check balance
    private func checkBalance(forAccount accountId: String, amount: Double) async throws -> Bool {
        let accountURLComponents = try createURLComponents(path: "/accounts/\(accountId)")
        let (data, response) = try await URLSession.shared.data(for: createRequest(url: accountURLComponents.url!))
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NessieError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NessieError.serverError(httpResponse.statusCode)
        }
        
        let account = try JSONDecoder().decode(Account.self, from: data)
        return account.balance >= amount
    }
    
    // Added comment: New helper function to perform transfer
    private func performTransfer(fromAccount: String, toAccount: String, amount: Double) async throws -> Bool {
        let transferURLComponents = try createURLComponents(path: "/accounts/\(fromAccount)/transfers")
        var request = createRequest(url: transferURLComponents.url!)
        request.httpMethod = "POST"
        
        let transferData: [String: Any] = [
            "medium": "balance",
            "payee_id": toAccount,
            "amount": amount,
            "transaction_date": ISO8601DateFormatter().string(from: Date())
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: transferData)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NessieError.invalidResponse
        }
        
        return httpResponse.statusCode == 201
    }
    
    // Added comment: Helper function to create URL components
    private func createURLComponents(path: String) throws -> URLComponents {
        guard var components = URLComponents(string: baseURL) else {
            throw NessieError.invalidURL
        }
        components.path = path
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        return components
    }
    
    // Added comment: Helper function to create request with common headers
    private func createRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
}

// Simplified models
private struct Account: Codable {
    let balance: Double
    
    private enum CodingKeys: String, CodingKey {
        case balance
    }
}

// Single error enum
enum PaymentError: LocalizedError {
    case insufficientFunds
    
    var errorDescription: String? {
        switch self {
        case .insufficientFunds:
            return "Insufficient funds for transaction"
        }
    }
}
