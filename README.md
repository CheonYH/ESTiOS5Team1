
# 이스트캠프 프론티어 2기 iOS 앱 개발자 부트캠프 - 3차 프로젝트 1조

# 👾 PlayerLounge
> **취향의 맞는 게임을 찾고 게임에 맞는 공략을 찾아라**
<p align="center">
  <img width="1536" height="1024" alt="mainLogo" src="https://github.com/user-attachments/assets/93965e86-e74b-47fc-a7f3-b723f0671a06" />
</p>

## 📑 앱 설명

* PC, 모바일, 플레이스테이션 등 모든 게임기기과 게임의 장르를 본인의 취향에 맞게 검색하고 추천 받습니다.
* 사용자가 맞춤 추천, 실시간 트렌드, 최신게임 모두 추천 합니다.
* 챗봇을 통하여 게임 정보를 자세히 검색하고 공략을 질문하며 개인의 게임 어시스턴트로 사용합니다.
* 게임마다 리뷰와 평점을 통해 사람들과 소통하고 공감합니다.

## 💡 주요기능

1. 홈 화면 (MainPage)
   * 최신 트렌드 게임, 실시단 트랜드 게임과 같이 인기있는 게임을 추천해줍니다.
   * 장르별 검색 바로가기, 검색 기능을 사용하여 검색으로 바로 넘어갈 수 있습니다.
  
2. 상세 페이지 (DetailView)
   * 게임 상세정보
   * 리뷰기능 & 별점
   * 게임 프리뷰 유튜브 영상
   * 메타크리틱 점수

3. 게임 찾기 (SearchView)
   * 장르, 게임 플랫폼(게임기기)별 상세 검색 가능
   * 더해서 필터기능을 통해 평점별, 최신인기별 게임검색 가능
   * 게임카드에 있는 하트를 눌러서 나만의 게임 라이브러리 생성

4. 내 게임 (LibraryView)
   * 하트를 눌러서 저장한 게임 검색

5. 프로필 (Profile)
   * 개인의 프로필 수정
   * 닉네임 변경
   * 로그아웃
   * 회원탈퇴
  
6. 챗봇 (Chatbot)
   * 1 대 1 맞춤 대화
   * 게임공략과 관련된 대화들만 가능

## ✨ 핵심 기술
1. 🗃️ 기술스택(Tech Stack)
   * 프레임워크: SwiftUI, Combine, Swift Concurrency(async/await, @MainActor, actor)
   * 데이터관리: SwiftData(채팅방/메시지 영속화)
   * 보안: CryptoKit(AES.GCM, 대화내용 암호화 저장), Keychain(암호화 키 저장/복호화용 키 관리)
   * 머신러닝: CoreML(Game vs Non-Game 분류모델, Game Intent 분류모델)
   * API 연동: IGDB API, 자체 REST API
   * 네트워킹: URLSession(비동기 API 통신)
   * 서버: Vapor(Swift), JWT 인증, Google 소셜 로그인
   * UI/UX: iPhone 대응
2. 🖥️ 서버 저장소
   * https://github.com/CheonYH/iOS5Team1
  
## 📁 프로젝트 구조
    ESTiOS5Team1/
    ├── App/                      # 앱의 진입점 및 전역 설정
    │   └── ESTiOS5Team1App.swift
    │
    ├── Model/                    # 데이터 및 비즈니스 로직 (Domain Layer)
    │   ├── Entity/               # 순수 도메인 모델 (Game, Review 등)
    │   ├── DTO/                  # 서버 통신을 위한 데이터 객체 (Firebase, IGDB)
    │   ├── Presentation/         # UI 전용 데이터 모델
    │   └── ViewModel/            # 비즈니스 로직 및 상태 관리 (MVVM)
    │       ├── Auth/             # 인증 및 회원가입 로직
    │       ├── Chatbot/          # AI 챗봇 인터랙션 로직
    │       ├── IGDB/             # 게임 데이터 연동 및 필터링
    │       └── Search/           # 검색 및 즐겨찾기 관리
    │
    ├── View/                     # SwiftUI 기반 UI 계층 (Presentation Layer)
    │   ├── Auth/                 # 로그인 및 회원가입 화면
    │   ├── Main/                 # 홈, 장르별 탐색, 트렌딩 화면
    │   ├── Detail/               # 게임 상세 정보 및 리뷰 섹션
    │   ├── Chatbot/              # AI 챗봇 채팅 화면
    │   ├── Search/               # 필터 기능이 포함된 검색 화면
    │   └── Common/               # 앱 전역에서 재사용되는 UI 컴포넌트 (Toast, Card, etc.)
    │
    ├── Service/                  # 네트워크 및 외부 API 연동
    │   ├── Auth/                 # Firebase/Social 인증 서비스
    │   ├── IGDB/                 # IGDB 게임 데이터 API 서비스
    │   └── Chatbot/              # Alan AI 챗봇 통신 클라이언트
    │
    ├── Security/                 # 보안 및 로컬 데이터 저장
    │   └── Store/                # SwiftData, Keychain, UserDefaults 관리
    │
    ├── Support/                  # 앱 보조 유틸리티 및 AI 처리
    │   ├── AlanCoordinator.swift # AI 음성/채팅 코디네이터
    │   └── TextClassifier.swift  # ML 기반 텍스트 분류 어댑터
    │
    ├── Common/                   # 공통 유틸리티 및 확장(Extension)
    │   ├── Extensions/           # SwiftUI 및 기초 타입 확장
    │   └── Types/                # 공통 상수 및 유효성 검사 로직
    │
    └── Assets.xcassets/          # 이미지, 컬러셋 등 앱 리소스

## 🖥️ 앱 주요 화면
| 홈화면 (MainView) | 게임찾기(SearchView) | 내 게임 (LibraryView) | 챗봇 (Chanbot) | 프로필 (Profile) |
|:---:|:---:|:---:|:---:|:---:|
| <img width="315" height="652" alt="MainView" src="https://github.com/user-attachments/assets/4f62654d-50ab-40be-9cd9-4d6a56da0693" /> | <img width="315" height="652" alt="SearchView" src="https://github.com/user-attachments/assets/b20ec6f6-7985-4523-987f-2567b803c1f0" /> | <img width="315" height="652" alt="LibraryView" src="https://github.com/user-attachments/assets/4e34c7c1-79d3-403f-b4c8-30b05f0735da" /> | <img width="315" height="652" alt="Chatbot" src="https://github.com/user-attachments/assets/56e32e02-aa67-44c6-89ce-48ceda1c468c" /> | <img width="315" height="652" alt="ProfileView" src="https://github.com/user-attachments/assets/78212894-66f3-4443-828a-1ad69b5895bc" />






## 🧑‍🤝‍🧑 협업 문화

### 🌅 데일리 스크럼 & 코드 동기화
* **매일 오전 정기 회의**: 매일 아침 팀원들과 진행 상황을 공유하고, 전날 작성한 코드를 함께 훑어보며 당일의 목표를 설정했습니다. 이를 통해 병목 현상을 조기에 발견하고 해결했습니다.

### 🔍 촘촘한 코드 리뷰 (PR 기반)
* **1인 이상 승인 필수**: 모든 기능 구현은 GitHub PR(Pull Request)을 거쳤으며, 최소 1명 이상의 팀원이 코드를 상세히 리뷰한 뒤에만 Merge를 진행하여 코드 퀄리티를 상향 평준화했습니다.
* **건설적인 피드백**: 단순히 오류를 찾는 것을 넘어, 더 나은 로직이나 Swift Concurrency 활용법 등을 제안하며 서로의 성장을 도왔습니다.

### 📐 공동 설계 및 구조 기획
* **Shared Architecture**: 작업 시작 전, 앱의 전체적인 폴더 구조와 MVVM 패턴 적용 방식, 서비스 레이어 설계 등을 팀원 모두가 함께 기획했습니다. 덕분에 각자 맡은 부분을 구현하면서도 일관성 있는 코드를 유지할 수 있었습니다.

### 📝 코드 문서화 (Documentation)
* **협업을 위한 가이드**: 팀원이 작성한 함수나 컴포넌트를 즉시 이해하고 사용할 수 있도록, 상세한 주석과 문서화(Documentation) 작업을 병행했습니다. 이는 코드의 가독성을 높이고 팀 내 커뮤니케이션 비용을 획기적으로 줄이는 결과로 이어졌습니다.


## 🧩 특징

### 🤖 AI 기반의 맞춤형 게임 어시스턴트
* **지능형 문맥 파악**: **CoreML** 분류 모델을 탑재하여 일반 대화와 게임 관련 질문을 구분하고, 사용자의 의도(Intent)를 분석해 정확한 공략 정보를 제공합니다.
* **실시간 대화 가이드**: **Alan AI**를 연동하여 1:1 맞춤형 챗봇을 구현, 게임 플레이 중 궁금한 점을 즉각적으로 해결할 수 있는 개인 비서를 제공합니다.

### 🛡️ 보안 및 데이터 무결성 강화
* **종단간 암호화 저장**: 사용자의 채팅 내역을 **CryptoKit(AES.GCM)**으로 암호화하여 저장하며, 복호화 키는 **Keychain**에서 안전하게 관리하여 개인정보 보호를 극대화했습니다.
* **최신 데이터 영속성**: **SwiftData**를 채택하여 채팅방 및 메시지 데이터를 로컬 환경에 효율적으로 구조화하고 영속화했습니다.

### 🍏 Full-Stack Swift 생태계
* **통합 개발 환경**: 서버 인프라를 **Vapor(Swift)**로 구축하여 클라이언트와 서버 간의 데이터 모델 공유를 최적화하고, 유지보수 효율성을 높였습니다.
* **안전한 인증 시스템**: **JWT(JSON Web Token)** 및 구글 소셜 로그인을 통해 보안성이 검증된 사용자 인증 프로세스를 제공합니다.

### 🎮 방대한 데이터 레이크 및 탐색 경험
* **고성능 검색 및 필터링**: **IGDB API**를 활용하여 전 세계 수만 개의 게임 데이터를 플랫폼, 장르, 평점별로 세밀하게 필터링할 수 있는 강력한 검색 엔진을 구축했습니다.
* **반응형 UX/UI**: **Swift Concurrency(async/await)**를 활용해 대량의 게임 데이터를 비동기적으로 처리하며, 끊김 없는 부드러운 스크롤과 사용자 경험을 보장합니다.

### 📺 멀티미디어 통합 정보
* 메타크리틱 점수와 유튜브 프리뷰 영상을 상세 페이지 내에 통합하여, 사용자가 앱을 벗어나지 않고도 게임의 퀄리티를 다각도에서 판단할 수 있는 환경을 조성했습니다.

## 🗓️ 개발 기간
2025.12.30.화 - 2026.02.04.수 (약 25일)
***



## 👯 팀원 소개

| | | | |
|:---:|:---:|:---:|:---:|
| <img width="200" height="200" alt="image" src="https://github.com/user-attachments/assets/ea5c7812-dbab-44b2-8532-5a0dea6ff7a9" alt="김대현" /> |  <img width="200" height="200" alt="image" src="https://github.com/user-attachments/assets/6863b073-e682-4cbb-8106-5b6a647ed288" alt="이찬희" />| <img width="200" height="200" alt="image" src="https://github.com/user-attachments/assets/7f9d5000-f972-48ad-83b9-42bb08f3f9d5" alt="최재영" /> | <img width="200" height="200" alt="image" src="https://github.com/user-attachments/assets/e2bfd524-b4ed-4ecf-9656-7e133cad6f6f" alt="천용휘" /> |
| **iOS** | **iOS** | **iOS** | **iOS** |
| **[김대현](https://github.com/Lala-roid)**<br> |**[이찬희](https://github.com/KyleLee02)**<br>| **[최재영](https://github.com/nox9807)**<br> | **[천용휘](https://github.com/CheonYH)**<br> |
| 개발 / 기획  | 개발 / 기획  | 개발 / 기획 | 개발 / 기획 |
