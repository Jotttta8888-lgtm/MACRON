import SwiftUI

struct DetailView: View {
    let selectedTab: Int
    
    var body: some View {
        Group {
            switch selectedTab {
            case 0: DashboardView()
            case 1: ChatView()
            case 2: CalendarView()
            case 3: NotesView()
            case 4: RemindersView()
            case 5: FinderView()
            case 6: SafariView()
            case 7: MailView()
            case 8: FocusView()
            case 9: ResearchView()
            case 10: AnalyticsView()
            case 11: CustomCommandsView()
            default: DashboardView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
