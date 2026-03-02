import SwiftUI

struct PermissionPromptView: View {
    let permissionService: PermissionService

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.dashed.badge.record")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Screen Recording Permission Required")
                .font(.headline)

            Text("SeemlessScreen needs Screen Recording access to capture window content. Please grant access in System Settings, then relaunch the app.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Open System Settings") {
                permissionService.openScreenRecordingSettings()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(width: 400)
    }
}
