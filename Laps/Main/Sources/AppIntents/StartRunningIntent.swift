//
//  StartRunningIntent.swift
//  Feature
//
//  Created by Moon kyu Jung on 6/26/25.
//  Copyright © 2025 mooq. All rights reserved.
//

import AppIntents
import SwiftUI

struct StartRunningIntent: AppIntent {
    static var title: LocalizedStringResource = "기록 시작"
    static var description = IntentDescription("러닝 기록을 시작합니다")
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        NotificationCenter.default.post(name: .startRunningFromSiri, object: nil)
        return .result()
    }
}

struct StopRunningIntent: AppIntent {
    static var title: LocalizedStringResource = "기록 중지"
    static var description = IntentDescription("러닝 기록을 중지합니다")
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        NotificationCenter.default.post(name: .stopRunningFromSiri, object: nil)
        return .result()
    }
}

