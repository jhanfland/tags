import SwiftUI

struct SearchCriteria {
    var searchText: String = ""
    var selectedGender: SearchView.Gender = .mens
    var selectedTopSizes: Set<String> = []
    var selectedBottomSizes: Set<String> = []
    var selectedShoeSizes: Set<String> = []
    var selectedCategory: String? = nil
    var selectedSubcategories: Set<String> = []
    var selectedBrands: Set<String> = []
    var selectedConditions: Set<String> = []
    var selectedColors: Set<String> = []
    var selectedSources: Set<String> = []
    var selectedAges: Set<String> = []
}
