import SwiftUI

// Optimized SearchResultsTabs with shared components
struct SearchResultsTabs: View {
    @Binding var searchCriteria: SearchCriteria
    @State private var expandedCategory: String?
    @State private var frameHeight: CGFloat = 90

    // Computed properties for category management
    private var allCategories: [String] {
        var categories = CategoryData.filterCategories.filter { $0 != "Subcategory" }
        if searchCriteria.selectedCategory != nil {
            categories.insert("Subcategory", at: 1)
        }
        return categories
    }

    private var orderedCategories: [String] {
        let selected = allCategories.filter { isFilterActive($0) }
        let unselected = allCategories.filter { !isFilterActive($0) }
        return selected + unselected
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    FilterButtonGrid(
                        categories: orderedCategories,
                        expandedCategory: $expandedCategory,
                        isFilterActive: isFilterActive,
                        onTap: toggleCategory
                    )
                    
                    if let category = expandedCategory {
                        FilterOptionsGrid(
                            category: category,
                            options: getOptionsForCategory(category),
                            selectedOptions: getSelectedOptionsForCategory(category),
                            onSelect: { option in
                                handleSelection(category: category, option: option)
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
        }
        .frame(height: frameHeight)
        .background(Color.white.opacity(0.9))
        .animation(.spring(), value: frameHeight)
        .onChange(of: expandedCategory) { _, _ in
            withAnimation {
                frameHeight = expandedCategory == nil ? 90 : 220
            }
        }
    }

    // Private helper methods
    private func toggleCategory(_ category: String) {
        withAnimation {
            expandedCategory = expandedCategory == category ? nil : category
        }
    }

    private func isFilterActive(_ category: String) -> Bool {
        AppUtilities.shared.isFilterActive(category, in: searchCriteria)
    }

    private func getOptionsForCategory(_ category: String) -> [String] {
        AppUtilities.shared.getOptionsForCategory(category, searchCriteria: searchCriteria)
    }

    private func getSelectedOptionsForCategory(_ category: String) -> Set<String> {
        AppUtilities.shared.getSelectedOptionsForCategory(category, from: searchCriteria)
    }

    private func handleSelection(category: String, option: String) {
        AppUtilities.shared.handleFilterSelection(
            category: category,
            option: option,
            searchCriteria: &searchCriteria,
            expandedCategory: &expandedCategory
        )
    }
}

// Grid components for filter buttons
struct FilterButtonGrid: View {
    let categories: [String]
    @Binding var expandedCategory: String?
    let isFilterActive: (String) -> Bool
    let onTap: (String) -> Void

    var body: some View {
        WrappingHStack(categories) { category in
            SharedFilterButton(
                title: category,
                isSelected: isFilterActive(category),
                isExpanded: expandedCategory == category,
                action: { onTap(category) }
            )
        }
    }
}

// Grid component for filter options
struct FilterOptionsGrid: View {
    let category: String
    let options: [String]
    let selectedOptions: Set<String>
    let onSelect: (String) -> Void

    var body: some View {
        WrappingHStack(options) { option in
            SharedFilterButton(
                title: option,
                isSelected: selectedOptions.contains(option),
                isExpanded: false,
                action: { onSelect(option) }
            )
        }
        .offset(y: 60)
    }
}

// Generic wrapping stack for flexible layouts
struct WrappingHStack<Data: RandomAccessCollection, V: View>: View where Data.Element: Hashable {
    let data: Data
    let viewGenerator: (Data.Element) -> V
    
    init(_ data: Data, @ViewBuilder viewGenerator: @escaping (Data.Element) -> V) {
        self.data = data
        self.viewGenerator = viewGenerator
    }
    
    var body: some View {
        GeometryReader { geometry in
            generateContent(in: geometry)
        }
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        let containerWidth = geometry.size.width

        return ZStack(alignment: .topLeading) {
            ForEach(Array(data.enumerated()), id: \.element) { index, item in
                viewGenerator(item)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                    .alignmentGuide(.leading) { dimension in
                        _ = width
                        if (width + dimension.width) > containerWidth {
                            width = 0
                            height -= dimension.height
                        }
                        let offset = width
                        if index == data.count - 1 {
                            width = 0
                        } else {
                            width += dimension.width
                        }
                        return -offset
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if index == data.count - 1 {
                            height = 0
                        }
                        return result
                    }
            }
        }
    }
}

// Preview provider for SearchResultsTabs
struct SearchResultsTabs_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultsTabs(searchCriteria: .constant(SearchCriteria()))
    }
}
