import SwiftUI

struct KingfisherTestView: View {

    @State private var selectedAge: GracAge = .all

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                Text("연령 필터 테스트")
                    .font(.title3.bold())
                    .padding(.top, 12)

                Picker("연령 필터", selection: $selectedAge) {
                    Text("전체").tag(GracAge.all)
                    Text("12세").tag(GracAge.twelve)
                    Text("15세").tag(GracAge.fifteen)
                    Text("청불").tag(GracAge.nineteen)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                NavigationLink {
                    FilteredResultsView(age: selectedAge)
                } label: {
                    Text("조회하기")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Filter Test")
        }
    }
}

#Preview {
    KingfisherTestView()
}

/// 테스트용 연령 표시 텍스트
///
/// - Important:
///   실제 프로덕션 UI에서는 사용하지 않고,
///   KingfisherTestView에서 연령 매핑 결과를 눈으로 확인하기 위한 용도입니다.
extension GameListItem {
    var ageLabelForTest: String {
        switch gracAge {
        case .all: return "전체"
        case .twelve: return "12세"
        case .fifteen: return "15세"
        case .nineteen: return "청불"
        }
    }
}
