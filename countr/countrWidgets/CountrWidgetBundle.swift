import WidgetKit
import SwiftUI

@main
struct CountrWidgetBundle: WidgetBundle {
    var body: some Widget {
        CountrSmallWidget()
        CountrMediumWidget()
        CountrLockWidget()
    }
}
