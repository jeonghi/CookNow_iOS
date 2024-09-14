//
//  Environment.swift
//  ProjectDescriptionHelpers
//
//  Created by 쩡화니 on 6/1/24.
//

import ProjectDescription

public extension Environment {
  static let organizationName = "com.cooknow"
  static let appName = "app"
  static var bundleId: String {
    "\(organizationName).\(appName)"
  }
  static let forPreview = true
  static let destinations: Destinations = [.iPhone]
  static let minimumDeploymentVersion = "17.0"
  static var deploymentTargets: DeploymentTargets {
    .iOS(minimumDeploymentVersion)
  }
}
