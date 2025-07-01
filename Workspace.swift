//
//  Workspace.swift
//  Config
//
//  Created by Moon kyu Jung on 2023/06/27.
//


import ProjectDescription
import ProjectDescriptionHelpers

private func projectNameWith(module: Module) -> Path {
    return "\(Workspace.workspaceName)/\(module.name)"
}

let workspace = Workspace(
    name: Workspace.workspaceName,
    projects: [
        "\(Workspace.workspaceName)/\(mainProjectName)",
    ] + Module.allCases.map({ projectNameWith(module: $0) })
)
