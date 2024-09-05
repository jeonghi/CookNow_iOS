//
//  IngredientBoxView.swift
//  IngredientBox
//
//  Created by 쩡화니 on 7/3/24.
//

import SwiftUI
import DesignSystem
import DesignSystemFoundation
import ComposableArchitecture
import Common
import Domain

// MARK: Properties
public struct IngredientBoxView: BaseFeatureViewType {
  
  public typealias Core = IngredientBoxCore
  public let store: StoreOf<Core>
  
  @ObservedObject public var viewStore: ViewStore<ViewState, CoreAction>
  
  public struct ViewState: Equatable {
    var isLoading: Bool
    var searchText: String
    var selectedCategory: IngredientCategory?
    var categories: [IngredientCategory]
    var currCategoryIngredients: [Ingredient]
    var ingredientBox: [Ingredient]
    var showingSheet: Bool
    var showingNext: Bool
    var ingredientBoxActive: Bool {
      !ingredientBox.isEmpty
    }
    
    public init(state: CoreState) {
      isLoading = state.isLoading
      searchText = state.searchText
      selectedCategory = state.selectedCategory
      categories = state.categories
      currCategoryIngredients = state.currCategoryIngredients
      ingredientBox = state.selectedingredientBox
      showingSheet = state.showingSheet
      showingNext = state.showingNext
    }
  }
  
  public init(
    _ store: StoreOf<Core> = .init(
      initialState: Core.State()
    ){
      Core()
    }
  ) {
    self.store = store
    self.viewStore = ViewStore(store, observe: ViewState.init)
  }
}

// MARK: Metrics
extension IngredientBoxView {
  
  private enum Metric {
    static let horizontalPadding: CGFloat = 20
    static let bottomPadding: CGFloat = 20
    static let headerSpacing: CGFloat = 8
    static let segmentControlHeight: CGFloat = 35
    static let kerning: CGFloat = -0.6
    static let searchBarMaxLength: Int = 30
    static let searchBarPlaceholder: String = "재료를 입력하세요."
    static let infoLabelText: String = "내 냉장고에 있는 재료들을 선택하고\n정보를 입력해보세요!"
    
    static let gridItemVerticalSpacing: CGFloat = 28
    static let gridItemHorizontalSpacing: CGFloat = 15
    static let gridVerticalPadding: CGFloat = 20
    static let gridHorizontalPadding: CGFloat = 20
    static let itemInnerSpacing: CGFloat = 6
    
    static let bottomSheetScrollViewVerticalPadding: CGFloat = 15
    static let bottomSheetScrollViewHorizontalPadding: CGFloat = 20
    static let bottomSheetScrollViewHeight: CGFloat = 440
    static let bottomSheetGridHorizontalSpacing: CGFloat = 5
    static let bottomSheetGridVerticalPadding: CGFloat = 18
    static let bottomSheetButtonHorizontalSpacing: CGFloat = 10
    static let bottomSheetButtonHorizontalPadding: CGFloat = 20
    static let bottomSheetButtonVerticalPadding: CGFloat = 8
  }
}

// MARK: Layout
extension IngredientBoxView: View {
  
  public var body: some View {
    VStack(spacing: 0) {
      VStack(spacing: 20) {
        ZStack(alignment: .bottom) {
          Image.asset(.ingredientBoxHomeHeaderBackground)
            .resizable()
            .scaledToFit()
          VStack(alignment: .leading, spacing: Metric.headerSpacing) {
            infoLabel()
            searchBar()
          } //: VStack
          .padding(.horizontal, Metric.horizontalPadding)
        } //: ZStask
        ingredientSegmentControl()
      } //: VStack
      .background(Color.asset(.white))
      
      ScrollView(.vertical, showsIndicators: true) {
        ingredientGridView()
          .padding(.vertical, Metric.gridVerticalPadding)
        makeIngredientBox().opacity(0)
      }
    }
    .applyIf(viewStore.ingredientBoxActive) {
     $0.overlay(alignment: .bottom) {
        Button(action: {
          viewStore.send(.ingredientBoxTapped)
        }) {
          makeIngredientBox()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
      }
    }
    .navigationDestination(isPresented: viewStore.binding(get: \.showingNext, send: CoreAction.showingNext)) {
      IfLetStore(inputFormStore) { store in
        IngredientInputFormView(store)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.asset(.bgMain))
    .ignoresSafeArea(edges: [.horizontal, .top])
    .kerning(Metric.kerning) // 자간 -0.6
    .cnLoading(viewStore.isLoading)
    .onLoad {
      viewStore.send(.onLoad)
    }
    .cnSheet(isPresented: viewStore.binding(get: \.showingSheet, send: CoreAction.showingSheet)) {
      makeBottomSheet()
    }
  }
}

// MARK: Components
extension IngredientBoxView {
  
  @ViewBuilder
  private func headerSectionBackgroundImage() -> some View {
    Image.asset(.ingredientBoxHomeHeaderBackground)
      .resizable()
      .scaledToFit()
  }
  
  @ViewBuilder
  private func searchBar() -> some View {
    CNSearchBar(
      text: viewStore.binding(
        get: \.searchText,
        send: CoreAction.updateSearchText
      ),
      placeholder: Metric.searchBarPlaceholder,
      maxLength: Metric.searchBarMaxLength
    )
  }
  
  @ViewBuilder
  private func infoLabel() -> some View {
    Text(Metric.infoLabelText)
      .multilineTextAlignment(.leading)
      .font(.asset(.caption))
      .lineLimit(2)
      .foregroundStyle(Color.asset(.gray800))
  }
  
  @ViewBuilder
  private func ingredientSegmentControl() -> some View {
    
    ZStack {
      if let selectedCategory = viewStore.selectedCategory {
        CNSegmentControl<IngredientCategory>(
          segments: viewStore.categories,
          selected: viewStore.binding(
            get: { state in selectedCategory },
            send: CoreAction.selectCategory
          ),
          label: {
            Text($0.catergoryName)
          }
        )
        .frame(height: Metric.segmentControlHeight)
      }
    }
    .frame(maxWidth: .infinity)
  }
  
  @ViewBuilder
  private func ingredientGridView() -> some View {
    
    let columns = [GridItem](repeating: .init(.flexible(), spacing: Metric.gridItemHorizontalSpacing), count: 4)
    
    LazyVGrid(columns: columns, spacing: Metric.gridItemVerticalSpacing) {
      ForEach(viewStore.currCategoryIngredients, id: \.self) { ingredient in
        ingredientGridItemView(item: ingredient)
      }
    }
    .padding(.horizontal, Metric.gridHorizontalPadding)
  }
  
  @ViewBuilder
  private func ingredientGridItemView(item: Ingredient) -> some View {
    
    let isContained: Bool = viewStore.ingredientBox.contains(item)
    
    VStack(spacing: Metric.itemInnerSpacing) {
      
      Button(action: {
        if(isContained) {
          viewStore.send(.putOutIngredient(item))
        } else {
          viewStore.send(.putInIngredient(item))
        }
      }){
        ZStack {
          Color.asset(.white)
          CNAsyncImage(item.imageUrl)
            .aspectRatio(1, contentMode: .fit)
            .padding(2)
        }
        .overlay {
          Color.black.opacity(isContained ? 0.4 : 0.0)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .bottomTrailing) {
          makeButton(for: isContained)
            .offset(x: 4, y: 4)
        }
      }
      
      Text(item.name)
        .foregroundStyle(Color.asset(.black))
        .font(.asset(.bodyBold1))
    }
  }
  
  @ViewBuilder
  private func makeButton(for isContained: Bool) -> some View {
    Circle()
      .fill(Color.asset(isContained ? .danger500 : .primary500))
      .frame(width: 24, height: 24)
      .overlay {
        Image(systemName: isContained ? "minus" : "plus")
          .foregroundStyle(Color.asset(.white))
      }
  }
  
  @ViewBuilder
  private func makeIngredientBox() -> some View {
    HStack(spacing: 10) {
      
      Image(systemName: "basket")
        .foregroundStyle(Color.asset(.white))
        .frame(width: 24, height: 24)
        .padding(9)
        .background(Color.asset(.primary500))
        .clipShape(Circle())
        .overlay(alignment: .bottomTrailing) {
          Circle()
            .fill(Color.asset(.danger500))
            .frame(width: 20, height: 20)
            .overlay {
              Text("\(viewStore.ingredientBox.count)")
                .foregroundStyle(Color.asset(.white))
                .font(.asset(.bodyBold))
            }
            .offset(x: 2, y: 2)
        }
      
      VStack(alignment: .leading, spacing: 5) {
        Text("재료 정보 입력")
          .font(.asset(.subhead2))
          .foregroundStyle(Color.asset(.white))
        Text("선택한 재료의 상세 정보 입력하러 가기")
          .font(.asset(.body1))
          .foregroundStyle(Color.asset(.gray300))
      }
      
      Spacer()
      
      Image(systemName: "arrow.up.forward")
        .font(.asset(.bodyBold3))
        .foregroundStyle(Color.asset(.white))
        .padding(5)
      
    }
    .padding()
    .frame(maxWidth: .infinity)
    .background(Color.black.opacity(0.8))
    .clipShape(RoundedRectangle(cornerRadius: 50))
  }
}

// MARK: 시트 뷰
extension IngredientBoxView {
  
  private func makeBottomSheet() -> some View {
    VStack(alignment: .leading) {
      VStack(alignment: .leading, spacing: 10) {
        Text("선택 재료 확인하기")
          .font(.asset(.headline1))
        Text("내가 선택한 재료들이 맞나요?")
          .font(.asset(.caption))
      } //: VStack
      .foregroundStyle(Color.asset(.gray800))
      
      ScrollView(.vertical, showsIndicators: false) {
        makeBottomSheetGrid()
//          .padding(.horizontal, Metric.bottomSheetScrollViewHorizontalPadding)
      }
      .frame(height: Metric.bottomSheetScrollViewHeight)
      .frame(maxWidth: .infinity)
      .padding(.vertical, Metric.bottomSheetScrollViewVerticalPadding)
      
      HStack(spacing: Metric.bottomSheetButtonHorizontalSpacing) {
        
        Button(action: {
          viewStore.send(.continueSelectionButtonTapped)
        }) {
          Text("계속 담기")
        }.buttonStyle(StateButtonStyle.secondary(.default))
        
        Button(action: {
          viewStore.send(.finishSelectionButtonTapped)
        }) {
          Text("재료 확인")
        }
        .buttonStyle(StateButtonStyle.primary(.default))
      } //: HStack
//      .padding(.horizontal, Metric.bottomSheetButtonHorizontalPadding)
      .padding(.vertical, Metric.bottomSheetButtonVerticalPadding)
    }
  }
  
  private func makeBottomSheetGrid() -> some View {
    LazyVGrid(columns: [GridItem].init(repeating: .init(), count: 4)) {
      ForEach(viewStore.ingredientBox, id: \.self) {
        makeBottomSheetGridItem(for: $0)
      }
    }
  }
  
  private func makeBottomSheetGridItem(for item: Ingredient) -> some View {
    VStack(spacing: 5) {
      CNAsyncImage(item.imageUrl)
      Text(item.name)
        .font(.asset(.bodyBold1))
        .foregroundStyle(Color.asset(.gray800))
    }
  }
}

private extension IngredientBoxView {
  var inputFormStore: Store<IngredientInputFormCore.State?, IngredientInputFormCore.Action> {
    return store.scope(state: \.ingredientInputFormState, action: CoreAction.ingredientInputFormAction)
  }
}


#Preview {
  NavigationView {
    IngredientBoxView()
      .toolbar {
        ToolbarItemGroup(placement: .principal) {
          Text("재료함")
            .font(.asset(.title1))
        }
      }
      .environment(\.locale, .init(identifier: "ko"))
  }
}

