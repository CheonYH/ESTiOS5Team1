//
//  DetailView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/7/26.
//

import SwiftUI
import WebKit

// MARK: - Detail View

/// 게임 상세 정보를 보여주는 화면입니다.
///
/// `gameId`를 기반으로 `GameDetailViewModel`이 데이터를 로드하며,
/// 상단의 대표 정보(`DetailInfoBox`), 소개(`GameSummaryBox`),
/// 추가 정보(개발사/퍼블리셔/출시년도/스토어), 트레일러 영상,
/// 챗봇 이동 CTA, 리뷰 영역을 순차적으로 구성합니다.
///
/// - Note:
///     상세 화면에서는 하단 탭바를 숨기기 위해 `TabBarState.isHidden`을 제어합니다.

struct DetailView: View {

    /// 조회할 게임의 고유 ID
    let gameId: Int

    /// (샘플/임시) 화면에서 사용할 평점 값
    @State var rating: Double = 4

    /// 게임 상세 데이터를 로드/보관하는 뷰모델
    @StateObject private var viewModel: GameDetailViewModel

    /// 탭바 노출 여부를 제어하는 상태 객체
    @EnvironmentObject var tabBarState: TabBarState

    /// 챗봇(루트) 화면 전환 여부
    @State var showRoot: Bool = false
    @Environment(\.dismiss) private var dismiss

    /// 지정한 `gameId`로 상세 화면을 초기화합니다.
    ///
    /// - Parameter gameId: 조회할 게임의 고유 ID
    init(gameId: Int) {
        self.gameId = gameId
        self._viewModel = StateObject(wrappedValue: GameDetailViewModel(gameId: gameId))
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    Text("상세 정보")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Spacer()

                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 0.5)
                ScrollView {
                    if let item = viewModel.item {
                        DetailInfoBox(item: item)
                        GameSummaryBox(item: item)

                        VStack(alignment: .leading, spacing: 12) {
                            TitleBox(title: "추가 정보", showsSeeAll: false, onSeeAllTap: nil)

                            infoRow(label: "개발사", value: joinedOrDash(item.developers))
                            infoRow(label: "퍼블리셔", value: joinedOrDash(item.publishers))
                            infoRow(label: "출시년도", value: item.releaseYear)

                            if let website = item.officialWebsite {
                                infoLink(label: "공식 사이트", title: "홈페이지로 이동", url: website)
                            }

                            let visibleStores = item.stores.filter { $0.name.lowercased() != "unknown" }
                            if !visibleStores.isEmpty {
                                HStack(alignment: .top, spacing: 8) {
                                    Text("스토어")
                                        .foregroundStyle(.gray.opacity(0.7))
                                        .frame(width: 80, alignment: .leading)
                                    ForEach(visibleStores) { store in
                                        Link(store.name, destination: store.url)
                                            .foregroundStyle(.purplePrimary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.pv10)
                        .padding(.vertical, 12)

                        if let trailer = item.trailers.first {
                            VStack(alignment: .leading, spacing: 12) {
                                TitleBox(title: "영상", showsSeeAll: false, onSeeAllTap: nil)
                                WebVideoPlayer(url: trailer)
                                    .frame(height: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                        }

                        GoChatBotBox(showRoot: $showRoot)

                        ReviewSection(
                            gameId: item.id,
                            onReviewChanged: {
                                await viewModel.refreshReviewData()
                            }
                        )
                    } else if viewModel.isLoading {
                        ProgressView("Loading...")
                            .padding()
                    } else if let error = viewModel.error {
                        Text("오류 발생: \(error.localizedDescription)")
                            .foregroundColor(.red)
                    }
                }
                .scrollIndicators(.hidden)

            }
        }
        .task {
            await viewModel.load()
        }
        .navigationDestination(isPresented: $showRoot) {
            RootTabView()
        }
        .onAppear {
            tabBarState.isHidden = true
        }
        .onDisappear {
            if !showRoot {
                tabBarState.isHidden = false
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    /// “라벨 - 값” 형태의 정보 행을 생성합니다.
    ///
    /// - Parameters:
    ///   - label: 좌측 라벨 텍스트(예: 개발사)
    ///   - value: 우측 값 텍스트
    /// - Returns: 정보 행을 표현하는 뷰
    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .foregroundStyle(.gray.opacity(0.7))
                .frame(width: 80, alignment: .leading)
            Text(value)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// “라벨 - 링크” 형태의 정보 행을 생성합니다.
    ///
    /// - Parameters:
    ///   - label: 좌측 라벨 텍스트
    ///   - title: 링크로 보여줄 텍스트
    ///   - url: 이동할 URL
    /// - Returns: 링크 정보 행을 표현하는 뷰
    private func infoLink(label: String, title: String, url: URL) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .foregroundStyle(.gray.opacity(0.7))
                .frame(width: 80, alignment: .leading)
            Link(title, destination: url)
                .foregroundStyle(.purplePrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
        }
    }

    /// 문자열 배열을 쉼표로 합치고, 비어있으면 대시(–)를 반환합니다.
    ///
    /// - Parameter values: 합칠 문자열 배열
    /// - Returns: 합쳐진 문자열 또는 "–"
    private func joinedOrDash(_ values: [String]) -> String {
        values.isEmpty ? "–" : values.joined(separator: ", ")
    }
}

// MARK: - Web Video Player

/// YouTube(또는 웹 영상) URL을 인라인으로 표시하기 위한 WKWebView 래퍼입니다.
///
/// SwiftUI에서 웹 기반 플레이어를 쉽게 재사용할 수 있도록 `UIViewRepresentable`로 감쌉니다.
/// iOS에서 인라인 재생을 위해 `allowsInlineMediaPlayback` 등을 설정하며,
/// 스크롤을 비활성화해 카드 형태의 영역 안에서 깔끔하게 보이도록 구성합니다.

private struct WebVideoPlayer: UIViewRepresentable {
    let url: URL

    /// WKWebView 로딩 상태/에러를 로깅하기 위한 네비게이션 델리게이트
    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("[WebVideoPlayer] didFail:", error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("[WebVideoPlayer] didFailProvisional:", error)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("[WebVideoPlayer] didFinish load")
        }
    }

    /// WKWebView 델리게이트를 연결하기 위한 Coordinator를 생성합니다.
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// WKWebView 인스턴스를 생성하고, 인라인 재생/비영구 스토리지 등의 설정을 적용합니다.
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    /// 전달받은 URL을 임베드(가능하면 YouTube nocookie) 형태로 변환해 HTML을 로드합니다.
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let embed = embedURL(from: url).absoluteString
        let html = """
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
        <style>
        body { margin: 0; background: transparent; }
        .container { position: relative; padding-top: 56.25%; }
        iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0; }
        </style>
        </head>
        <body>
        <div class="container">
            <iframe src="\(embed)?playsinline=1&autoplay=0&rel=0&modestbranding=1&controls=1&enablejsapi=1&origin=https://localhost"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowfullscreen>
            </iframe>
        </div>
        </body>
        </html>
        """
        uiView.loadHTMLString(html, baseURL: nil)
    }

    /// 가능한 경우 YouTube URL을 임베드 URL로 변환합니다.
    ///
    /// - Parameter url: 원본 영상 URL
    /// - Returns: 임베드 가능한 URL (변환 불가 시 원본 반환)
    private func embedURL(from url: URL) -> URL {
        if let videoId = youtubeVideoId(from: url) {
            return URL(string: "https://www.youtube-nocookie.com/embed/\(videoId)") ?? url
        }
        return url
    }

    /// YouTube URL에서 videoId를 추출합니다.
    ///
    /// 지원 형태:
    /// - `https://youtu.be/{id}`
    /// - `https://www.youtube.com/watch?v={id}`
    ///
    /// - Parameter url: 분석할 URL
    /// - Returns: videoId (추출 실패 시 nil)
    private func youtubeVideoId(from url: URL) -> String? {
        if url.host?.contains("youtu") == true {
            if url.host?.contains("youtu.be") == true {
                return url.lastPathComponent
            }
            if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
                return queryItems.first(where: { $0.name == "v" })?.value
            }
        }
        return nil
    }
}

#Preview {
    DetailView(gameId: 119133)
        .environmentObject(TabBarState())
}
