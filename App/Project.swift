import ProjectDescription
import ProjectDescriptionHelpers


let project = Project(
  name: "App",
  settings: .projectSettings,
  targets: [
    .target(
      name: "App",
      destinations: .iOS,
      product: .app,
      bundleId: "\(Environment.bundleId)",
      infoPlist: .default,
      sources: ["Sources/**"],
      resources: ["Resources/**"],
//      scripts: [.swiftLint],
      dependencies: [],
      settings: .targetSettings
    )
  ],
  schemes: Scheme.allSchemes(for: ["App"], executable: "App")
)
