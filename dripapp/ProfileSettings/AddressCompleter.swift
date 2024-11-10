import SwiftUI
import MapKit
import CoreLocation
import Combine

struct AddressSuggestion: Identifiable {
    let id = UUID()
    let streetNumber: String
    let streetName: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
    
    var fullAddress: String {
        "\(streetNumber) \(streetName)\n\(city), \(state) \(zipCode)"
    }

    var cityStateZip: String {
        "\(city), \(state) \(zipCode)"
    }
}

class AddressCompleter: NSObject, ObservableObject {
    @Published var results: [AddressSuggestion] = []
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchCancellable: AnyCancellable?
    private var debounceTimer: AnyCancellable?
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
    }
    
    func updateQueryFragment(_ fragment: String) {
        debounceTimer?.cancel()
        debounceTimer = Just(fragment)
            .delay(for: .milliseconds(400), scheduler: RunLoop.main) // Adjust the delay as needed
            .sink { [weak self] query in
                self?.searchCompleter.queryFragment = query
            }
    }
    
    private func performReverseGeocoding(for completion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { [weak self] (response, error) in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
            
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                guard let placemark = placemarks?.first else { return }
                
                let suggestion = AddressSuggestion(
                    streetNumber: placemark.subThoroughfare ?? "",
                    streetName: placemark.thoroughfare ?? "",
                    city: placemark.locality ?? "",
                    state: placemark.administrativeArea ?? "",
                    zipCode: placemark.postalCode ?? "",
                    country: placemark.country ?? ""
                )
                
                DispatchQueue.main.async {
                    self?.results.append(suggestion)
                }
            }
        }
    }
}

extension AddressCompleter: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results.removeAll()
        for completion in completer.results {
            performReverseGeocoding(for: completion)
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Address lookup failed with error: \(error.localizedDescription)")
    }
}

struct AddressSuggestionRow: View {
    let suggestion: AddressSuggestion

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(.blue)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(suggestion.streetNumber) \(suggestion.streetName)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text(suggestion.cityStateZip)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
    }
}

struct ContactInformationSection: View {
    @Binding var name: String
    @Binding var email: String
    @Binding var phone: String
    @Binding var address: String
    @ObservedObject var addressCompleter: AddressCompleter
    @Binding var showingAddressSuggestions: Bool
    @FocusState.Binding var focusedField: SettingsView.Field?

    var onUpdate: () -> Void

    var body: some View {
        VStack(spacing: 15) {
            SettingsButton(
                icon: "person",
                placeholder: "Enter name",
                text: $name,
                keyboardType: .default,
                isEditing: .constant(false),
                onCommit: onUpdate
            )
            .focused($focusedField, equals: .name)

            SettingsButton(
                icon: "envelope",
                placeholder: "Enter email",
                text: $email,
                keyboardType: .emailAddress,
                isEditing: .constant(false),
                onCommit: onUpdate
            )
            .focused($focusedField, equals: .email)

            SettingsButton(
                icon: "phone",
                placeholder: "Enter phone number",
                text: Binding(
                    get: { formatPhoneNumber(phone) },
                    set: { phone = $0.filter { $0.isNumber } }
                ),
                keyboardType: .numberPad,
                isEditing: .constant(false),
                onCommit: onUpdate
            )
            .focused($focusedField, equals: .phone)

            AddressView(
                name: name,
                address: $address,
                addressCompleter: addressCompleter
            )
            .focused($focusedField, equals: .address)
        }
    }
    
    private func formatPhoneNumber(_ phoneNumber: String) -> String {
        let cleaned = phoneNumber.filter { $0.isNumber }
        var result = ""
        for (index, char) in cleaned.enumerated() {
            if index == 3 || index == 6 {
                result += "-"
            }
            result.append(char)
        }
        return result
    }
}


struct SettingsButton: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    @Binding var isEditing: Bool
    var onCommit: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.black)
                .frame(width: 30)
            
            TextField(placeholder, text: $text, onCommit: {
                isEditing = false
                onCommit?()
            })
            .foregroundColor(isEditing ? .black : .blue)
            .font(.body)
            .keyboardType(keyboardType)

        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .onTapGesture {
            isEditing = true
        }
    }
}
