//
//  SimplePublisher.swift
//  Usecase
//
//  Created by dev team on 1/8/24.
//  Copyright © 2024 perspective. All rights reserved.
//

import Combine

public extension Publishers {
    static func fetchData<T>(_ request: @escaping () async ->(T?)) -> AnyPublisher<T?, Error> {
        return Future<T?, Error> { promise in
            Task {
                let data = await request()
                guard let value = data else {
                    promise(.failure(SimplePublisherError.datanil))
//                    promise(.success(nil))
                    return
                }
                promise(.success(value))
            }
        }
        .eraseToAnyPublisher()
    }
}

enum SimplePublisherError: Error {
    case datanil
}
