import ProjectDescription

/// Project helpers are functions that simplify the way you define your project.
/// Share code to create targets, settings, dependencies,
/// Create your own conventions, e.g: a func that makes sure all shared targets are "static frameworks"
/// See https://docs.tuist.io/guides/helpers/

public let mainProjectName = "Main"

public let coreDataPath: Path = "../../Coredata.xcdatamodeld"
public let infoplistpath: Path = "../../Info.plist"
public let entitlementsPath: Path = "../../main.entitlements"
public let widgetInfoplistpath: Path = "../../Widget-Info.plist"
public let widgetEntitlementsPath: Path = "../../widget.entitlements"

public let settings: Settings = .settings(
    base: [
            "OTHER_LDFLAGS": "-Objc",
          ],
    configurations: [
            .debug(name: .debug),
            .release(name: .release),
        ]
)

extension Workspace {
    public static let workspaceName = "Laps"
}

extension Project {
    public static var targetVersion: String { "17.0" }
    public static var widgetVersion: String { "17.0" }
}

extension Project {
    
    public static func create(
        name: String,
        packages: [Package],
        settings: Settings? = nil,
        targets: [Target],
        schemes: [Scheme]
    ) -> Project {
        Project(
            name: name,
            organizationName: "organizationName",
            options: .options(
                disableBundleAccessors: true,
                disableSynthesizedResourceAccessors: true
            ),
            packages: packages,
            settings: settings,
            targets: targets,
            schemes: schemes
        )
    }
}

extension Target {
    public static func create(
        targetName: String,
        infoPlist: Path?,
        entitlements: Path? = nil,
        sources: SourceFilesList? = nil,
        resources: ResourceFileElements? = nil,
        product: Product,
        scripts: [TargetScript],
        dependencies: [TargetDependency],
        settings: Settings?,
        coreDataModels: [CoreDataModel] = []
    ) -> Target {
        Target.target(name: targetName,
                      destinations: [.iPhone, .iPad, .macWithiPadDesign],
                      product: product,
                      productName: targetName,
                      bundleId: "com" + "." + "organizationName" + "." + Workspace.workspaceName + (infoPlist == nil ? ".\(targetName)" : (product == .appExtension ? ".Widget" : "")),
                      deploymentTargets: .iOS(product == .appExtension ? Project.widgetVersion : Project.targetVersion),
                      infoPlist: infoPlist == nil ? .default : InfoPlist.file(path: infoPlist!),
                      sources: sources ?? ["Sources/**"],
                      resources: resources ?? ["Resources/**"],
                      entitlements: .file(path: entitlements!),
                      scripts: scripts,
                      dependencies: dependencies,
                      settings: settings,
                      coreDataModels: coreDataModels,
                      environmentVariables: [:],
                      launchArguments: [],
                      additionalFiles: [],
                      buildRules: [])
    }

    public static func createWithoutResource(
        targetName: String,
        product: Product,
        scripts: [TargetScript],
        dependencies: [TargetDependency],
        settings: Settings?,
        coreDataModels: [ProjectDescription.CoreDataModel] = []
    ) -> Target {
        Target.target(name: targetName,
                      destinations: [.iPhone, .iPad, .macWithiPadDesign],
                      product: product,
                      productName: targetName,
                      bundleId: "com" + "." + "organizationName" + "." + Workspace.workspaceName + "." + "\(product == .unitTests ? "\(targetName)Tests" : targetName)",
                      deploymentTargets: .iOS(Project.targetVersion),
                      infoPlist: .default,
                      sources: [product == .unitTests ? "Tests/**" : "Sources/**"],
                      resources: nil,
                      entitlements: nil,
                      scripts: scripts,
                      dependencies: dependencies,
                      settings: settings,
                      coreDataModels: coreDataModels,
                      environmentVariables: [:],
                      launchArguments: [],
                      additionalFiles: [],
                      buildRules: [])
    }
}

public extension TargetDependency {
    static let featureProject: TargetDependency = .project(
        target: Module.feature.name,
        path: "../\(Module.feature.name)"
    )
    static let usecaseProject: TargetDependency = .project(
        target: Module.usecase.name,
        path: "../\(Module.usecase.name)"
    )
    static let coreProject: TargetDependency = .project(
        target: Module.core.name,
        path: "../\(Module.core.name)"
    )
    static let userInterfaceProject: TargetDependency = .project(
        target: Module.userinterface.name,
        path: "../\(Module.userinterface.name)"
    )
    
    static let widgetTargetDependency: TargetDependency = .target(name: Module.widget.name)
}

public enum Module: String, CaseIterable {
    case feature, usecase, core, userinterface, widget
}

public extension Module {
    var name: String {
        switch self {
        case .feature:
            return "Feature"
        case .usecase:
            return "Usecase"
        case .core:
            return "Core"
        case .userinterface:
            return "UserInterface"
        case .widget:
            return "Widget"
        }
    }
}
