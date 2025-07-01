#!/bin/bash

# 빌드
xcodebuild -scheme Main -destination 'id=D58B0080-1B1D-4915-97CD-67D02C97D397' build

# 앱 설치
xcrun simctl install D58B0080-1B1D-4915-97CD-67D02C97D397 "/Users/moonkyujung/Library/Developer/Xcode/DerivedData/Fishes-ezvffxljhezvtsftqthamspldosm/Build/Products/Main.app"

# 앱 실행
xcrun simctl launch D58B0080-1B1D-4915-97CD-67D02C97D397 personal.mooq.Fishes/
