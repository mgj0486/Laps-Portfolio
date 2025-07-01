## ✨ 소개

**MyLaps**(가제)는 피트니스 트래킹 iOS 애플리케이션입니다. GPS 기반 실시간 트래킹부터 HealthKit 통합, 편리한 러닝을 위한 Siri Intent부터 위젯, Live Activity를 제공합니다.

## 🎯 주요 기능

<table>
<tr width="100%">

### 🗺️ 실시간 GPS 트래킹
- 경로 추적
- 실시간 거리, 속도, 페이스 측정

</tr>
<tr width="100%">

### 📱 Live Activities
- 잠금 화면에서 실시간 상태 확인
- Dynamic Island 지원

</tr>
<tr width="100%">

### ❤️ HealthKit 통합
- Apple Health과의 연동
- 칼로리 자동 기록
- 건강 데이터 관리

</tr>
<tr width="100%">

### 🎙️ Siri 단축어
- "Siri야, MyLabs에서 기록시작 하자."
- 음성으로 간편하게 제어

</tr>
</table>

## 🛠 기술 스택

### 개발 환경
- **Language**: Swift 6.0
- **UI Framework**: SwiftUI
- **Architecture**: Clean Architecture, MVVM

### 사용 기술
```
SwiftUI | CoreData | Combine | Tuist 
HealthKit| MapKit

```

## 🏗 프로젝트 구조

```
MyLaps/
├── 📱 Main              # 앱 진입점, 라이프사이클
├── 🎨 Feature           # UI 컴포넌트, ViewModels
├── 💡 UseCase           # 비즈니스 로직
├── 🔧 Core              # 공통 유틸리티
├── 🎯 UserInterface     # 재사용 UI 컴포넌트
└── 🪟 Widget            # 홈 화면 위젯
```

### 모듈 의존성
```mermaid
graph TD
    A[Main] --> B[Feature]
    A --> F[Widget]
    B --> C[UseCase]
    B --> E[UserInterface]
    C --> D[Core]
    E --> D
    F --> C
```

## 🚀 시작하기

### 요구사항
- Xcode 15.0+
- iOS 17.0+
- [Tuist](https://tuist.io) 4.0+

### 설치 및 실행

1. **저장소 클론**
```bash
git clone https://github.com/yourusername/MyLaps.git
cd MyLaps
```

2. **Tuist 설치** (이미 설치되어 있다면 생략)
```bash
curl -Ls https://install.tuist.io | bash
```

3. **프로젝트 생성**
```bash
tuist generate
```

4. **실행**
```bash
./run-ios.sh
# 또는 Xcode에서 Main scheme 선택 후 실행
```

## 🧪 테스트

```bash
# Feature 모듈 테스트
xcodebuild test -scheme FeatureTest -destination 'platform=iOS Simulator,name=iPhone 15'

# UseCase 모듈 테스트  
xcodebuild test -scheme UsecaseTest -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 📋 권한 설정

MyLaps는 다음 권한을 요청합니다:

| 권한 | 용도 |
|------|------|
| 🏃‍♂️ **Motion & Fitness** | 활동 데이터 수집 |
| 📍 **위치 (항상/사용 중)** | GPS 트래킹 |
| ❤️ **HealthKit** | 건강 데이터 연동 |
| 🔔 **알림** | 러닝 알림 |

## 🤝 기여하기

프로젝트 개선에 기여해주세요!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 👨‍💻 개발자

**Moon Kyu Jung**
- GitHub: [@moonkyujung](https://github.com/moonkyujung)
- Email: your.email@example.com

---

<div align="center">
  
**[⬆ 맨 위로 돌아가기](#-mylaps)**

Made with ❤️ in Korea

</div>
