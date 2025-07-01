//
//  AppShortcutsProvider.swift
//  Feature
//
//  Created by Moon kyu Jung on 6/26/25.
//  Copyright © 2025 mooq. All rights reserved.
//

import AppIntents

struct LapsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartRunningIntent(),
            phrases: [
                "\(.applicationName)에서 기록 시작하자",
                "\(.applicationName) 기록 시작하자",
                "\(.applicationName)에서 러닝 시작하자",
                "\(.applicationName)에서 달리기 시작하자"
            ],
            shortTitle: "기록 시작",
            systemImageName: "figure.run"
        )
        
        AppShortcut(
            intent: StopRunningIntent(),
            phrases: [
                "\(.applicationName)에서 기록 중지하자",
                "\(.applicationName) 기록 중지하자",
                "\(.applicationName)에서 러닝 중지하자",
                "\(.applicationName)에서 달리기 중지하자"
            ],
            shortTitle: "기록 중지",
            systemImageName: "stop.circle"
        )
    }
}
