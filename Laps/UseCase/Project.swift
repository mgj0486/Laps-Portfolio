//
//  Project.swift
//  FirstManifests
//
//  Created by dev team on 2023/06/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let usecaseTarget = Target.createWithoutResource(
    targetName: Module.usecase.name,
    product: .framework,
    scripts: [],
    dependencies: [
        .coreProject,
//        .external(name: "Moya"),
//        .external(name: "CombineMoya"),
    ],
    settings: nil,
    coreDataModels: []
)


let project = Project.create(
    name: Module.usecase.name,
    packages: [
//        .remote(url: "https://github.com/Moya/Moya.git", requirement: .upToNextMajor(from: "15.0.0")),
    ],
    targets: [
        usecaseTarget,
        Target.createWithoutResource(
            targetName: Module.usecase.name + "Test",
            product: .unitTests,
            scripts: [],
            dependencies: [
                .target(name: Module.usecase.name),
//                .external(name: "Moya"),
            ],
            settings: nil
        ),
    ],
    schemes: []
)
