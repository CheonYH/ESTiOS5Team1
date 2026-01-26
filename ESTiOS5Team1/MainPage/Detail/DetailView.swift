//
//  DetailView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/7/26.
//

import SwiftUI
import WebKit

struct DetailView: View {

    let gameId: Int
    @State var rating: Double = 4
    @StateObject private var viewModel: GameDetailViewModel
    @EnvironmentObject var tabBarState: TabBarState
    
    init(gameId: Int) {
        self.gameId = gameId
        self._viewModel = StateObject(wrappedValue: GameDetailViewModel(gameId: gameId))
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            VStack(spacing: 16) {
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
                                infoLink(label: "공식 사이트", url: website)
                            }
                            
                            let visibleStores = item.stores.filter { $0.name.lowercased() != "unknown" }
                            if !visibleStores.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("스토어")
                                        .foregroundStyle(.gray.opacity(0.7))
                                    ForEach(visibleStores) { store in
                                        Link(store.name, destination: store.url)
                                            .foregroundStyle(.purplePrimary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
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

                        ReviewSection(gameId: item.id)
                    } else if viewModel.isLoading {
                        ProgressView("Loading...")
                            .padding()
                    } else if let error = viewModel.error {
                        Text("오류 발생: \(error.localizedDescription)")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .onAppear { tabBarState.isHidden = true }
        .onDisappear { tabBarState.isHidden = false }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 4) {
                    Text("상세 정보")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 0.5)
        }
    }
    
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
    
    private func infoLink(label: String, url: URL) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .foregroundStyle(.gray.opacity(0.7))
                .frame(width: 80, alignment: .leading)
            Link(url.absoluteString, destination: url)
                .foregroundStyle(.purplePrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func joinedOrDash(_ values: [String]) -> String {
        values.isEmpty ? "–" : values.joined(separator: ", ")
    }
}

private struct WebVideoPlayer: UIViewRepresentable {
    let url: URL
    
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
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
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
    
    private func embedURL(from url: URL) -> URL {
        if let videoId = youtubeVideoId(from: url) {
            return URL(string: "https://www.youtube-nocookie.com/embed/\(videoId)") ?? url
        }
        return url
    }
    
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
