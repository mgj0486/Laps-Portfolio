import ProjectDescription
import ProjectDescriptionHelpers


private let mainTarget = Target.create(
    targetName: mainProjectName,
    infoPlist: infoplistpath,
    entitlements: entitlementsPath,
    product: .app,
    scripts: [],
    dependencies: [
        .featureProject,
        .widgetTargetDependency,
    ],
    settings: settings,
    coreDataModels: [CoreDataModel.coreDataModel(coreDataPath)]
)

//let widgetTarget = Target.create(targetName: Module.widget.name,
//                                     infoPlist: widgetInfoplistpath,
//                                     entitlements: widgetEntitlementsPath,
//                                     sources: ["../Widget/Sources/**"],
//                                     resources: ["../Widget/Resources/**"],
//                                     product: .appExtension,
//                                     scripts: [],
//                                     dependencies: [
//                                        .sdk(name: "SwiftUI", type: .framework),
//                                        .sdk(name: "WidgetKit", type: .framework),
//                                     ],
//                                 settings: settings)

let project = Project.create(
    name: mainProjectName,
    packages: [],
    targets: [
        mainTarget,
        .target(
            name: Module.widget.name,
            destinations: [.iPhone, .iPad, .appleVisionWithiPadDesign],
            product: .appExtension,
            bundleId: "personal.\(Workspace.organization_name).\(Workspace.workspaceName).\(Module.widget.name)",
            deploymentTargets: .iOS(Project.widgetVersion),
            infoPlist: InfoPlist.file(path: widgetInfoplistpath),
            sources: ["../\(Module.widget.name)/Sources/**"],
            resources: ["../\(Module.widget.name)/Resources/**"],
            entitlements: .file(path: widgetEntitlementsPath),
            dependencies: [.featureProject],
            settings: settings
        )
    ],
    schemes: []
)
