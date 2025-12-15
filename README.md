# ☀️ SunnyPlanti (써니플랜티)

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Hive-FF6F00?style=for-the-badge&logo=hive&logoColor=white" />
</div>

> **"빛을 찾아 떠나는 나만의 정원"**
>
> 스마트폰 카메라로 실제 햇빛(조도)을 측정하여 가상의 반려 식물을 키우는 **게이미피케이션(Gamification) 힐링 앱**입니다.
<div align="center">
  <img src="assets/images/home_screenshot.png" width="200" alt="Main Screen">
  <img src="assets/images/camera_auth_screenshot.png" width="200" alt="Camera Screen">
  <img src="assets/images/codex_screenshot.png" width="200" alt="Codex Screen">
  <img src="assets/images/shop_screenshot.png" width="200" alt="Shop Screen">
</div>

---

## 📱 프로젝트 소개 (Introduction)

**SunnyPlanti**는 현대인의 부족한 야외 활동과 햇빛 쬐기 문제를 해결하기 위해 기획되었습니다. 사용자는 카메라를 통해 실제 빛 에너지를 모으는 '광합성 미션'을 수행하고, 산책(타이머)을 통해 식물을 성장시키며 성취감을 느낄 수 있습니다.

### 🌟 핵심 가치 (Core Value)
- **Interaction**: 카메라 센서를 활용해 현실의 빛이 게임에 영향을 주는 몰입형 경험 제공.
- **Habit Forming**: 하루 3번의 퀘스트 제한과 랜덤 보상 시스템으로 꾸준한 접속 유도.
- **Collection**: 나만의 화분 꾸미기와 다양한 꽃 도감 수집을 통한 재미 요소.

---

## 📸 주요 기능 (Key Features)

### 1. 🌿 메인 정원 & 성장 시스템 (`MainGardenScreen`)
- **실시간 성장 시각화**: 식물의 단계(씨앗 → 새싹 → 봉오리 → 꽃)에 따라 이미지가 동적으로 변화하며, `Stack` 위젯을 통해 화분과 식물을 자연스럽게 합성합니다.
- **타이머 & 상태 유지**: `DatabaseService`를 통해 앱이 종료되어도 산책 시간이 유지되며, 재접속 시 남은 시간을 계산하여 보여줍니다.
- **데일리 리셋 로직**: 하루가 지나면 퀘스트 횟수와 '오늘의 꽃'이 자동으로 초기화되는 날짜 기반 로직을 구현했습니다.

### 2. ☀️ 카메라 조도 분석 (`CameraAuthScreen`)
- **YUV420 스트림 분석**: `camera` 패키지의 ImageStream을 활용, 영상 데이터의 Y(Luma, 밝기) 평면 픽셀 평균값을 실시간으로 계산합니다.
- **인터랙티브 게이지**: 일정 밝기(Lux) 이상이 감지되면 `Timer.periodic`을 통해 게이지가 부드럽게 차오르는 애니메이션 효과를 구현했습니다.
- **UX 최적화**: 정확한 센싱을 위해 측정 화면에서는 강제로 세로 모드(`portraitUp`)로 고정합니다.

### 3. 🛍 아이템 상점 (`ShopScreen`)
- **재화 경제 시스템**: 퀘스트 완료 보상(포인트)으로 다양한 디자인의 화분을 구매 및 장착할 수 있습니다.
- **예외 처리 & UX**: 잔액 부족 시 구매 불가 처리, 미공개 아이템(Coming Soon) 비활성화 처리 등 꼼꼼한 예외 처리가 적용되었습니다.
- **데이터 영속성**: 구매한 아이템 목록과 장착 상태는 로컬 DB(Hive)에 즉시 저장됩니다.

### 4. 📖 식물 도감 (`CodexScreen`)
- **랜덤 가챠 시스템**: 식물이 완전히 성장하면 랜덤한 꽃이 피어나며 도감에 등록됩니다.
- **조건부 렌더링**: 획득 여부에 따라 흑백(실루엣)과 컬러 이미지를 구분하여 수집 욕구를 자극합니다.

### 5. 🔔 로컬 알림 서비스 (`NotificationService`)
- **스마트 알림**: `flutter_local_notifications`와 `timezone`을 활용하여, 산책 타이머가 종료되는 정확한 시점에 푸시 알림을 전송합니다.
- **싱글톤 패턴**: 어디서든 접근 가능한 싱글톤 구조로 구현하여 메모리 효율성을 높였습니다.

---

## 🛠 기술 스택 (Tech Stack)

| 구분 | 기술 / 라이브러리 | 설명 |
|:---:|:---|:---|
| **Framework** | **Flutter (3.10+)** | iOS/Android 크로스 플랫폼 개발 |
| **Language** | **Dart** | 비동기 처리 및 강력한 타입 시스템 활용 |
| **Local DB** | **Hive** | 가볍고 빠른 NoSQL 저장소. 사용자 데이터(포인트, 도감, 퀘스트) 관리 |
| **Hardware** | **Camera** | 실시간 이미지 스트림 분석을 통한 커스텀 조도 센서 구현 |
| **Notification** | **Local Notifications** | 타이머 종료 시점 스케줄링 알림 |
| **Utils** | **Permission Handler** | 카메라 및 알림 권한 런타임 요청 |

---

## 📂 폴더 구조 (Directory Structure)

```text
lib/
├── main.dart                  # 앱 진입점 (초기화, 테마, 화면 방향 설정)
├── screens/
│   ├── main_garden_screen.dart # [Core] 메인 게임 루프 & UI 합성
│   ├── camera_auth_screen.dart # [Feature] 카메라 밝기 분석 로직
│   ├── shop_screen.dart        # [UI] 화분 상점 & 아이템 관리
│   └── codex_screen.dart       # [UI] 식물 도감 리스트
├── services/
│   ├── database_service.dart   # [Data] Hive CRUD 및 비즈니스 로직(날짜 계산 등)
│   └── notification_service.dart # [Util] 알림 초기화 및 스케줄링
└── widgets/                    # 공통 위젯 리소스