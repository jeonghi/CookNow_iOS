//
//  OnboardingCore.swift
//  Onboading
//
//  Created by 쩡화니 on 7/12/24.
//

import ComposableArchitecture
import Foundation

public struct OnboadingCore {
  
  // MARK: Dependency
  @Dependency(\.mainQueue) var mainQueue
  @Dependency(\.authService) var authService
  
  // MARK: constructor
  public init() {}
}

extension OnboadingCore: Reducer {
  
  // MARK: Public
  public struct State {
    var isLoading: Bool = false
    var searchText: String = ""
    var isAnimating: Bool = true
    var animationProgressTime: CGFloat = .zero
    var isVisibleLoginRegion: Bool {
      animationProgressTime > 0.7
    }
    
    public init() {
      
    }
  }
  
  enum Route {
    case detail
  }
  
  public enum Action {
    // Life Cycle
    case onLoad
    case onAppear
    case onDisappear
    case isLoading(Bool)
    case isAnimating(Bool)
    // MARK: Button Action
    case googleSignInButtonTapped // 구글로그인 버튼 클릭
    case appleSignInButtonTapped // 애플로그인 버튼 클릭
    // MARK: Binding
    case updateAnimationProgressTime(CGFloat)
  }
  
  public var body: some ReducerOf<Self> {
    
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .none
      case .onDisappear:
        return .none
      case .onLoad:
        return .none
      case .isLoading(let isLoading):
        state.isLoading = isLoading
        return .none
      case .isAnimating(let isAnimating):
        state.isAnimating = isAnimating
        return .none
        
        // MARK: Button Action
      case .appleSignInButtonTapped:
        
        return .run { @MainActor send in
          do {
            try await authService.appleSignIn()
          } catch {
            
          }
        }
        
      case .googleSignInButtonTapped:
        
        return .run { @MainActor send in
          do {
            try await authService.googleSignIn()
          } catch {
            
          }
        }
        
        // MARK: Binding
      case .updateAnimationProgressTime(let updated):
        state.animationProgressTime = updated
        return .none
      }
    }
  }
}
