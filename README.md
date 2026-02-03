
# 이스트캠프 프론티어 2기 iOS 앱 개발자 부트캠프 - 3차 프로젝트 1조

# PlayerLounge
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

## 🧩 특징

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
