//
//  ColorAsset+Constants.swift
//  DesignSystem
//
//  Created by 쩡화니 on 6/2/24.
//

import DesignSystemFoundation


public extension ColorAsset {
  
  // MARK: Background
  static let bg100 = ColorAsset(named: "bg100", bundle: .module)
  static let bg200 = ColorAsset(named: "bg200", bundle: .module)
  static let bgMain = ColorAsset(named: "bg300", bundle: .module)
  static let overlayBackground = ColorAsset.black.with(alpha: 0.7)
  
  // MARK: Primary
  static let primary100 = ColorAsset(named: "primary100", bundle: .module)
  static let primary200 = ColorAsset(named: "primary200", bundle: .module)
  static let primary300 = ColorAsset(named: "primary300", bundle: .module)
  static let primary400 = ColorAsset(named: "primary400", bundle: .module)
  static let primary500 = ColorAsset(named: "primary500", bundle: .module)
  static let primary600 = ColorAsset(named: "primary600", bundle: .module)
  static let primary700 = ColorAsset(named: "primary700", bundle: .module)
  static let primary800 = ColorAsset(named: "primary800", bundle: .module)
  
  // MARK: Gray
  static let gray100 = ColorAsset(named: "gray100", bundle: .module)
  static let gray200 = ColorAsset(named: "gray200", bundle: .module)
  static let gray300 = ColorAsset(named: "gray300", bundle: .module)
  static let gray400 = ColorAsset(named: "gray400", bundle: .module)
  static let gray500 = ColorAsset(named: "gray500", bundle: .module)
  static let gray600 = ColorAsset(named: "gray600", bundle: .module)
  static let gray800 = ColorAsset(named: "gray800", bundle: .module)
  
  // MARK: Success
  static let success300 = ColorAsset(named: "success300", bundle: .module)
  static let success500 = ColorAsset(named: "success500", bundle: .module)
  static let success700 = ColorAsset(named: "success700", bundle: .module)
  
  // MARK: Info
  static let info300 = ColorAsset(named: "info300", bundle: .module)
  static let info500 = ColorAsset(named: "info500", bundle: .module)
  static let info700 = ColorAsset(named: "info700", bundle: .module)
  
  // MARK: Warning
  static let warning300 = ColorAsset(named: "warning300", bundle: .module)
  static let warning500 = ColorAsset(named: "warning500", bundle: .module)
  static let warning700 = ColorAsset(named: "warning700", bundle: .module)
  
  // MARK: Danger
  static let danger300 = ColorAsset(named: "danger300", bundle: .module)
  static let danger500 = ColorAsset(named: "danger500", bundle: .module)
}

#if canImport(SwiftUI)
import SwiftUI
#Preview {
  ScrollView {
    ColorAsset.bg100.toColor()
    ColorAsset.bg200.toColor()
    ColorAsset.bgMain.toColor()
  }
}
#endif
