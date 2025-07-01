//
//  Project.swift
//  FirstManifests
//
//  Created by dev team on 2023/06/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let featureTarget = Target.createWithoutResource(
    targetName: Module.feature.name,
    product: .framework,
    scripts: [],
    dependencies: [
        .usecaseProject,
        .userInterfaceProject,
//        .external(name: "RxSwift"),
//        .package(product: "ComposableArchitecture", type: .runtime),
    ],
    settings: nil,
    coreDataModels: [CoreDataModel.coreDataModel(coreDataPath)]
)

let project = Project.create(
    name: Module.feature.name,
    packages: [
//        .remote(url: "https://github.com/ReactiveX/RxSwift.git", requirement: .upToNextMajor(from: "6.0.0")),
//        .remote(url: "https://github.com/pointfreeco/swift-composable-architecture", requirement: .upToNextMinor(from: "1.9.2")),
    ],
    targets: [
        featureTarget,
        Target.createWithoutResource(
            targetName: Module.feature.name + "Test",
            product: .unitTests,
            scripts: [],
            dependencies: [
                .target(name: Module.feature.name),
            ],
            settings: nil
        ),
    ],
    schemes: []
)
