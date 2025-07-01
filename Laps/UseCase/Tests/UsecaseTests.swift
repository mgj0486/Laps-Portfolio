import Foundation
import XCTest
import Usecase
import MapKit

final class UsecaseTests: XCTestCase {
    let provider = MoyaProvider<BadanuriAPI>()
    
//    func test_getObsInfo() {
//        let expectation = XCTestExpectation(description: "Data fetched successfully")
//
//        provider.request(.getObsInfo(key: BadanuriAPI.key)) { result in
//            switch result {
//            case .success(let response):
//                guard let data = try? response.map(GetObsInfoResponse.self) else { return }
//                print(data)
//            case .failure(let error):
//                XCTAssertEqual(error.localizedDescription, "Mock API Response Failure")
//            }
//        }
//        
//        wait(for: [expectation], timeout: 5.0)
//    }
//    
//    func test_getWaveHeight() {
//        let expectation = XCTestExpectation(description: "Data fetched successfully")
//            
//        provider.request(.getWaveHeight(key: BadanuriAPI.key, obs: "TW_0062", date: "20250315")) { result in
//            switch result {
//            case .success(let response):
//                guard let data = try? response.map(GetWaveHeightResponse.self) else { return }
//                print(data)
//            case .failure(let error):
//                XCTAssertEqual(error.localizedDescription, "Mock API Response Failure")
//            }
//        }
//        
//        wait(for: [expectation], timeout: 5.0)
//    }
    
    func test_getObsTemp() {
        let expectation = XCTestExpectation(description: "Data fetched successfully")
        let date = Date.now
        Task {
            for i in 0..<15 {
                let targetDate = Calendar.current.date(byAdding: .day, value: i, to: date)!
                let dateString = targetDate.getFormattedDate(format: "yyyyMMdd")
                let sadf = await getLunarSunInfo(dateString: dateString)
                print(sadf)
                
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
//    func test_weatherkit() {
//        let expectation = XCTestExpectation(description: "Data fetched successfully")
//
//        WeatherKitAPI.shared.getWindInfo(10, latitude: 34.77333, longitude: 128.46) { data in
//            data.forEach { winddata in
//                print(winddata.date.getFormattedDate(format: "yyyy-MM-dd"), winddata.speed, winddata.highSpeed, winddata.msSpeed, winddata.direction)
//            }
//        }
//        
//        wait(for: [expectation], timeout: 5.0)
//
//    }
    
    
    func getLunarSunInfo(dateString: String) async -> String {
        var lunString = ""
        LunarSunAPI.provider.request(.getLunarInfo(key: LunarSunAPI.key, date: dateString)) { result in
            switch result {
            case .success(let response):
                let jsonString = String(data: response.data, encoding: .utf8)
                let yyyy = jsonString?.extractValue(for: "lunYear") ?? ""
                let MM = jsonString?.extractValue(for: "lunMonth") ?? ""
                let dd = jsonString?.extractValue(for: "lunDay") ?? ""
                lunString = yyyy + MM + dd
            case .failure(_):
                lunString = ""
            }
        }
        return lunString
    }
}
