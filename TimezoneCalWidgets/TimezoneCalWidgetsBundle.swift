import SwiftUI
import WidgetKit

@main
struct TimezoneCalWidgetsBundle: WidgetBundle {
    var body: some Widget {
        CalendarGlanceSmallWidget()
        MultiZoneOverlapMediumWidget()
        SixHourTimelineMediumWidget()
        LockScreenTimezoneWidget()
    }
}
