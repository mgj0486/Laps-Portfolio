//
//  Project.swift
//  ProjectDescriptionHelpers
//
//  Created by dev team on 1/9/24.
//

import ProjectDescription
import ProjectDescriptionHelpers

let uiTarget = Target.createWithoutResource(
    targetName: Module.userinterface.name,
    product: .framework,
    scripts: [],
    dependencies: [
        .coreProject
    ],
    settings: nil,
    coreDataModels: []
)

let project = Project.create(
    name: Module.userinterface.name,
    packages: [
    ],
    targets: [
        uiTarget
    ],
    schemes: []
)
