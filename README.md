
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
   * 로그아웃
  
6. 챗봇 (Chatbot)
   * 1 대 1 맞춤 대화
   * 게임공략과 관련된 대화들만 가능

## ✨ 핵심 기술
1. 🗃️ 기술스택(Tech Stack)
   * 프레임워크: SwiftUI, Combine, Swift Concurrency(async/await, @MainActor, actor)
   * 데이터관리: SwiftData(채팅방/메시지 영속화)
   * 라이브러리: SwiftUI Charts
   * 보안: CryptoKit(AES.GCM, 대화내용 암호화 저장), Keychain(암호화 키 저장/복호화용 키 관리)
   * 머신러닝: CoreML(Game vs Non-Game 분류모델, Game Intent 분류모델)
   * 네트워킹: URLSession(REST API호출)
   * UIUX: ipad(가로, 세로 대응), iphone 대응, Light, Dark Mode 대응
  
## 📁 프로젝트 구조


## 🖥️ 앱 주요 화면
| 홈화면 (MainView) | 게임찾기(SearchView) | 내 게임 (LibraryView) | 챗봇 (Chanbot) | 프로필 (Profile) |
|:---:|:---:|:---:|:---:|:---:|
| <img width="315" height="652" alt="MainView" src="https://github.com/user-attachments/assets/d84cb7d1-6c7c-4143-9b06-411e2e6e3e36" /> | <img width="315" height="652" alt="SearchView" src="https://github.com/user-attachments/assets/b00878f7-19fc-4cb7-8741-e91e8e0ad35b" /> | <img width="315" height="652" alt="LibraryView" src="https://github.com/user-attachments/assets/fc3a1b58-3e44-472f-9c59-8d36539d6f5d" /> | <img width="315" height="652" alt="Chatbot" src="https://github.com/user-attachments/assets/374dac9c-02a8-47cd-a006-053dafb5ba75" /> | <img width="315" height="652" alt="ProfileView" src="https://github.com/user-attachments/assets/fee8785b-26b9-4145-b312-82ac72bad38c" /> |

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
