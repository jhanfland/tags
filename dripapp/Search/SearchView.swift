import SwiftUI
import UIKit

struct SearchView: View {
    @State private var searchText = ""
    @State private var selectedGender: Gender = .mens
    @State private var selectedTopSizes: Set<String> = ["XL"]
    @State private var selectedBottomSizes: Set<String> = ["32"]
    @State private var selectedShoeSizes: Set<String> = ["12"]
    @State private var showingSizeSelector: SizeType?
    @State private var selectedCategory: String?
    @State private var selectedSubcategories: Set<String> = []
    @State private var selectedBrands: Set<String> = []
    @State private var selectedConditions: Set<String> = []
    @State private var selectedColors: Set<String> = []
    @State private var selectedSources: Set<String> = []
    @State private var selectedAges: Set<String> = []
    @FocusState private var isSearchFocused: Bool
    @State private var showingSearchResults = false
    @State private var searchCriteria = SearchCriteria()
    @State private var showingEditSearch = false
    @State private var scrollViewProxy: ScrollViewProxy?
    @StateObject private var cartManager = CartManager.shared
    @State private var showingSavedItems = false


    
    enum Gender: String {
        case mens = "Men's"
        case womens = "Women's"
    }
    
    enum SizeType: String, Identifiable {
        case top = "Tops"
        case bottom = "Bottoms"
        case shoe = "Shoes"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    HStack {
                        NavigationLink(destination: SavedItemsView()) {
                            HStack {
                                Text("Saved")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            selectedGender = selectedGender == .mens ? .womens : .mens
                            selectedCategory = nil
                            selectedSubcategories.removeAll()
                        }) {
                            Text(selectedGender.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                                )
                                .cornerRadius(15)
                        }
                        .frame(height: 30)
                        .padding(.leading, -25)
                        
                        Spacer()
                        
                        cartButton
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .sheet(isPresented: $showingSavedItems) {
                        SavedItemsView()
                    }
                    
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Add keywords", text: $searchText)
                            .focused($isSearchFocused)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top, 15)
                    .padding(.bottom, 10)
                    
                    ScrollView {
                        VStack(spacing: 15) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                ScrollViewReader { proxy in
                                    HStack(spacing: 13) {
                                        ForEach(categoriesForSelectedGender, id: \.0) { name, icon in
                                            Button(action: {
                                                withAnimation(.easeInOut(duration: 0.1)) {
                                                    selectedCategory = name
                                                }
                                            }) {
                                                VStack {
                                                    ZStack {
                                                        Circle()
                                                            .fill(selectedCategory == name ? Color.blue.opacity(0.1) : Color.clear)
                                                            .frame(width: 60, height: 60)
                                                        
                                                        Image(icon)
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fit)
                                                            .frame(width: 40, height: 40)
                                                            .foregroundColor(selectedCategory == name ? .blue : .primary)
                                                    }
                                                    Text(name)
                                                        .font(.caption)
                                                        .foregroundColor(selectedCategory == name ? .blue : .primary)
                                                }
                                            }
                                            .id(name)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .onAppear {
                                        scrollViewProxy = proxy
                                    }
                                    .onChange(of: selectedCategory) { oldValue, newValue in
                                        withAnimation {
                                            proxy.scrollTo(newValue, anchor: .center)
                                        }
                                    }
                                }
                            }.padding(.vertical, 20)
                            .frame(height: 80)
                            .id(selectedGender)
                            
                            .padding(.bottom, 40)
                            ModifiedFilterSection(
                                selectedGender: $selectedGender,
                                selectedCategory: $selectedCategory,
                                selectedSubcategories: $selectedSubcategories,
                                selectedSources: $selectedSources,
                                selectedConditions: $selectedConditions,
                                selectedBrands: $selectedBrands,
                                selectedAges: $selectedAges,
                                selectedColors: $selectedColors,
                                selectedTopSizes: $selectedTopSizes,
                                selectedBottomSizes: $selectedBottomSizes,
                                selectedShoeSizes: $selectedShoeSizes
                            ).padding(.top, -30)
                            
                            Spacer().frame(height: 100)
                            
                        }
                    }
                }
                
                VStack {
                                    Spacer()
                                    Button(action: {
                                        updateSearchCriteria()
                                        showingSearchResults = true
                                    }) {
                                        Text("Search")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .cornerRadius(25)
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 20)
                                }
                            }
                            .onChange(of: selectedGender) { _, _ in
                                withAnimation(.easeOut(duration: 0.4)) {
                                    selectedCategory = nil
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation(.easeOut(duration: 0.4)) {
                                            scrollViewProxy?.scrollTo(categoriesForSelectedGender.first?.0, anchor: .trailing)
                                        }
                                    }
                                }
                            }
                            .overlay(
                                Group {
                                    if let sizeType = showingSizeSelector {
                                        VStack {
                                            SizeDropdown(
                                                sizeType: sizeType,
                                                selectedSizes: binding(for: sizeType),
                                                allSizes: sizesFor(sizeType),
                                                showingSizeSelector: $showingSizeSelector
                                            )
                                            Spacer()
                                        }
                                        .background(
                                            Color.clear
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    showingSizeSelector = nil
                                                }
                                        )
                                    }
                                }
                            )
                            .navigationDestination(isPresented: $showingSearchResults) {
                                SearchResultsView(searchCriteria: $searchCriteria)
                            }
                        }
                    }

                                        
    var categoriesForSelectedGender: [(String, String)] {
        selectedGender == .mens ? CategoryData.mensSearchCategories : CategoryData.womensSearchCategories
    }
    private var cartButton: some View {
        NavigationLink(destination: Cart()) {
            Image(systemName: "cart")
                .font(.title2)
                .padding(.trailing, 20)
                .overlay(cartBadge)
        }
    }
    private var cartBadge: some View {
        Group {
            if cartManager.itemCount > 0 {
                Text("\(cartManager.itemCount)")
                    .font(.caption2)
                    .padding(5)
                    .background(Color.red)
                    .clipShape(Circle())
                    .foregroundColor(.white)
                    .offset(x: 10, y: -10)
            }
        }
    }
    private func positionFor(sizeType: SizeType, in geometry: GeometryProxy) -> CGFloat {
        let buttonWidth: CGFloat = 70
        let spacing: CGFloat = 5
        let totalWidth = buttonWidth * 4 + spacing * 3
        let startX = (geometry.size.width - totalWidth) / 2
        
        switch sizeType {
        case .top:
            return startX + buttonWidth * 1.5 + spacing
        case .bottom:
            return startX + buttonWidth * 2.5 + spacing * 2
        case .shoe:
            return startX + buttonWidth * 3.5 + spacing * 3
        }
    }
    private func binding(for sizeType: SizeType) -> Binding<Set<String>> {
        switch sizeType {
        case .top: return $selectedTopSizes
        case .bottom: return $selectedBottomSizes
        case .shoe: return $selectedShoeSizes
        }
    }
    private func updateSearchCriteria() {
        searchCriteria = SearchCriteria(
            searchText: searchText,
            selectedGender: selectedGender,
            selectedTopSizes: selectedTopSizes,
            selectedBottomSizes: selectedBottomSizes,
            selectedShoeSizes: selectedShoeSizes,
            selectedCategory: selectedCategory ?? "",
            selectedSubcategories: selectedSubcategories,
            selectedBrands: selectedBrands,
            selectedConditions: selectedConditions,
            selectedColors: selectedColors,
            selectedSources: selectedSources,
            selectedAges: selectedAges
        )
    }
    // Add comment: Using shared size handling logic
    private func sizesFor(_ sizeType: SizeType) -> [String] {
        switch sizeType {
        case .top, .bottom, .shoe:
            return AppUtilities.shared.getSizesForCategory(sizeType.rawValue)
        }
    }
    private func buttonWidth(for type: SizeType, in totalWidth: CGFloat) -> CGFloat {
        let spacing: CGFloat = 10 // Total spacing between buttons
        let availableWidth = totalWidth - spacing
        
        let topText = selectedTopSizes.isEmpty ? type.rawValue : selectedTopSizes.joined(separator: ", ")
        let bottomText = selectedBottomSizes.isEmpty ? type.rawValue : selectedBottomSizes.joined(separator: ", ")
        let shoeText = selectedShoeSizes.isEmpty ? type.rawValue : selectedShoeSizes.joined(separator: ", ")
        
        let topWidth = textWidth(topText)
        let bottomWidth = textWidth(bottomText)
        let shoeWidth = textWidth(shoeText)
        
        let totalTextWidth = topWidth + bottomWidth + shoeWidth
        
        switch type {
        case .top:
            return (topWidth / totalTextWidth) * availableWidth
        case .bottom:
            return (bottomWidth / totalTextWidth) * availableWidth
        case .shoe:
            return (shoeWidth / totalTextWidth) * availableWidth
        }
    }

    private func textWidth(_ text: String) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 17) // Adjust font size as needed
        let attributes = [NSAttributedString.Key.font: font]
        let size = (text as NSString).size(withAttributes: attributes)
        return size.width + 20 // Add some padding
    }
    
    }

struct SizeButton: View {
    let type: SearchView.SizeType
    @Binding var selectedSizes: Set<String>
    @Binding var showingSizeSelector: SearchView.SizeType?

    var body: some View {
        Button(action: {
            showingSizeSelector = (showingSizeSelector == type) ? nil : type
        }) {
            Text(selectedSizes.isEmpty ? type.rawValue : selectedSizes.joined(separator: ", "))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                )
                .cornerRadius(15)
        }
    }
}

import SwiftUI

struct SizeDropdown: View {
    let sizeType: SearchView.SizeType
    @Binding var selectedSizes: Set<String>
    let allSizes: [String]
    @Binding var showingSizeSelector: SearchView.SizeType?
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                Text(sizeType.rawValue)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .center) // Center the title
                                    .padding(.horizontal, 16)
                                    .padding(.top, 10)
                                    .padding(.bottom, 5)
                
                ForEach(allSizes, id: \.self) { size in
                    Button(action: {
                        if selectedSizes.contains(size) {
                            selectedSizes.remove(size)
                        } else {
                            selectedSizes.insert(size)
                        }
                    }) {
                        HStack {
                            Text(size)
                                .foregroundColor(.black)
                            Spacer()
                            if selectedSizes.contains(size) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                    }
                    if size != allSizes.last {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                    }
                }
            }
            .frame(width: 200) // Adjust this value to make the menu less wide
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 10)
            .position(x: geometry.size.width / 2, y: geometry.size.height - 480) // Adjust the position here
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    showingSizeSelector = nil
                }
        )
        .edgesIgnoringSafeArea(.all)
    }
}

struct ModifiedFilterSection: View {
    @Binding var selectedGender: SearchView.Gender
    @Binding var selectedCategory: String?
    @Binding var selectedSubcategories: Set<String>
    @Binding var selectedSources: Set<String>
    @Binding var selectedConditions: Set<String>
    @Binding var selectedBrands: Set<String>
    @Binding var selectedAges: Set<String>
    @Binding var selectedColors: Set<String>
    @Binding var selectedTopSizes: Set<String>
    @Binding var selectedBottomSizes: Set<String>
    @Binding var selectedShoeSizes: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let selectedCategory = selectedCategory {
                FilterRow(title: "Subcategory", options: subcategoriesFor(category: selectedCategory), selection: $selectedSubcategories, allowMultiple: true)
                
                // Size filter row
                if let sizeType = sizeTypeFor(category: selectedCategory) {
                    FilterRow(title: "Size", options: sizesFor(sizeType: sizeType), selection: sizeBindingFor(sizeType: sizeType), allowMultiple: true)
                }
            }
            
            FilterRow(title: "Source", options: CategoryData.sources, selection: $selectedSources, allowMultiple: true)
            FilterRow(title: "Condition", options: CategoryData.conditions, selection: $selectedConditions, allowMultiple: true)
            FilterRow(title: "Brand", options: CategoryData.brands, selection: $selectedBrands, allowMultiple: true)
            FilterRow(title: "Age", options: CategoryData.ages, selection: $selectedAges, allowMultiple: true)
            FilterRow(title: "Color", options: CategoryData.colors, selection: $selectedColors, allowMultiple: true)
        }
    }
    
    private func subcategoriesFor(category: String) -> [String] {
        if selectedGender == .mens {
            return CategoryData.mensSubcategories[category] ?? []
        } else {
            return CategoryData.womensSubcategories[category] ?? []
        }
    }
    
    private func sizeTypeFor(category: String) -> SearchView.SizeType? {
        switch category {
        case "Shirts", "Jackets", "Pullovers":
            return .top
        case "Bottoms":
            return .bottom
        case "Shoes":
            return .shoe
        default:
            return nil
        }
    }
    
    private func sizesFor(sizeType: SearchView.SizeType) -> [String] {
        switch sizeType {
        case .top:
            return CategoryData.topSizes
        case .bottom:
            return CategoryData.bottomSizes
        case .shoe:
            return CategoryData.shoeSizes
        }
    }
    
    private func sizeBindingFor(sizeType: SearchView.SizeType) -> Binding<Set<String>> {
        switch sizeType {
        case .top:
            return $selectedTopSizes
        case .bottom:
            return $selectedBottomSizes
        case .shoe:
            return $selectedShoeSizes
        }
    }
}


struct FilterRow: View {
    let title: String
    let options: [String]
    @Binding var selection: Set<String>
    let allowMultiple: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) { // Align the content to the left
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.top, 5)
                .padding(.leading, 20)
          
        
        
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            if allowMultiple {
                                if selection.contains(option) {
                                    selection.remove(option)
                                } else {
                                    selection.insert(option)
                                }
                            } else {
                                selection = [option]
                            }
                        }) {
                            Text(option)
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selection.contains(option) ? Color.blue.opacity(0.1) : Color.white)
                                .foregroundColor(selection.contains(option) ? .blue : .black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.black, lineWidth: 0.8)
                                )
                                .cornerRadius(15)
                        }
                    }
                }
                .padding(.leading, 20)
            }
        }
    }
}

    struct SearchView_Previews: PreviewProvider {
        static var previews: some View {
            SearchView()
        }
    }
struct SearchCriteria {
    var searchText: String = ""
    var selectedGender: SearchView.Gender = .mens
    var selectedTopSizes: Set<String> = []
    var selectedBottomSizes: Set<String> = []
    var selectedShoeSizes: Set<String> = []
    var selectedCategory: String?
    var selectedSubcategories: Set<String> = []
    var selectedBrands: Set<String> = []
    var selectedConditions: Set<String> = []
    var selectedColors: Set<String> = []
    var selectedSources: Set<String> = []
    var selectedAges: Set<String> = []
    var selectedStyles: Set<String> = []
}
