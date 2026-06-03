import SwiftUI

struct SkippedPackagesView: View {
    @EnvironmentObject private var viewModel: MenuBarViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Text("Skipped Packages")
                .font(.headline)
                .padding()

            Divider()

            if viewModel.rememberedSkipList.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("No packages saved")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                List(viewModel.rememberedSkipList.sorted(), id: \.self) { name in
                    HStack {
                        Text(name)
                        Spacer()
                        Button {
                            viewModel.rememberedSkipList.remove(name)
                        } label: {
                            Image(systemName: "xmark.circle")
                        }
                        .buttonStyle(.borderless)
                        .help("Remove \(name) from the saved skip list")
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(.plain)
            }

            Divider()

            HStack {
                Button("Remove All", role: .destructive) {
                    viewModel.rememberedSkipList = []
                }
                .disabled(viewModel.rememberedSkipList.isEmpty)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 360, height: 400)
    }
}
