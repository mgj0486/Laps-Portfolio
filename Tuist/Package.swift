// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // Customize the product types for specific package product
        // Default is .staticFramework
        productTypes: [
//            "Moya": .framework,
//            "RxSwift": .framework,
        ]
    )
#endif

let package = Package(
    name: "Laps",
    dependencies: [
//        .package(url: "https://github.com/Moya/Moya.git", .upToNextMajor(from: "15.0.0")),
//        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.0.0")),
    ]
)
