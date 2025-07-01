////
////  ApiClientManager.swift
////  Usecase
////
////  Created by Moon kyu Jung on 4/13/25.
////  Copyright © 2025 mooq. All rights reserved.
////
//
//import Foundation
//import Moya
//
//public class ApiClientManager {
//    public static let shared = ApiClientManager()
//    
//    public func getObsInfoAsync() async throws -> [ObsData] {
//        try await withCheckedThrowingContinuation { continuation in
//            BadanuriAPI.provider.request(.getObsInfo(key: BadanuriAPI.key)) { result in
//                switch result {
//                case .success(let response):
//                    guard let res = try? response.map(GetObsInfoResponse.self) else {
//                        continuation.resume(throwing: APIError.parsingError)
//                        return
//                    }
//                    continuation.resume(returning: res.obsDataArray)
//                case .failure(let error):
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }
//    
//    public func getTideInfo(code: String, dateString: String) async throws -> [TideData] {
//        try await withCheckedThrowingContinuation { continuation in
//            BadanuriAPI.provider.request(.getTide(key: BadanuriAPI.key, obs: code, date: dateString)) { result in
//                switch result {
//                case .success(let response):
//                    guard let res = try? response.map(GetTideResponse.self) else { return }
//                    continuation.resume(returning: res.tideData)
//                case .failure(let error):
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }
//    
//    public func getTempInfo(lat: String, lon: String) async throws -> [RomsTempData] {
//        try await withCheckedThrowingContinuation { continuation in
//            BadanuriAPI.provider.request(.getRomsTemp(key: BadanuriAPI.key, lat: lat, lon: lon)) { result in
//                switch result {
//                case .success(let response):
//                    guard let res = try? response.map(GetRomsTempResponse.self) else {
//                        continuation.resume(throwing: APIError.parsingError)
//                        return
//                    }
//                    continuation.resume(returning: res.romsTempData)
//                case .failure(let error):
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }
//    
//    public func getLunarSunInfo(dateString: String) async throws -> String {
//        try await withCheckedThrowingContinuation { continuation in
//            LunarSunAPI.provider.request(.getLunarInfo(key: LunarSunAPI.key, date: dateString)) { result in
//                switch result {
//                case .success(let response):
//                    let jsonString = String(data: response.data, encoding: .utf8)
//                    let yyyy = jsonString?.extractValue(for: "lunYear") ?? ""
//                    let MM = jsonString?.extractValue(for: "lunMonth") ?? ""
//                    let dd = jsonString?.extractValue(for: "lunDay") ?? ""
//                    let lunString = yyyy + MM + dd
//                    continuation.resume(returning: lunString)
//                case .failure(let error):
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }
//}
//
//enum APIError: Error {
//    case parsingError
//}
