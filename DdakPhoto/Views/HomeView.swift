import PhotosUI
import SwiftUI
import UIKit

struct HomeView: View {
    @StateObject private var model = ConversionViewModel()
    @AppStorage("targetKB") private var targetKB = 500
    @AppStorage("maxLongEdge") private var maxLongEdge = 0
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var customSetting: CustomSetting?
    @State private var sharePayload: SharePayload?
    @State private var showsAbout = false
    @State private var showsClearConfirmation = false
    @ScaledMetric(relativeTo: .largeTitle) private var heroFontSize: CGFloat = 40

    private var settings: ConversionSettings {
        ConversionSettings(
            maxBytes: targetKB * 1_000,
            maxLongEdge: maxLongEdge == 0 ? nil : maxLongEdge
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    brandHeader
                    introduction
                    settingsCard
                    if model.isBusy {
                        progressCard
                    }
                    if !model.successfulResults.isEmpty {
                        resultsCard
                    }
                    if !model.photos.isEmpty && !model.isBusy && model.successfulResults.isEmpty {
                        convertButton
                    }
                    if model.photos.isEmpty {
                        emptySelection
                    } else {
                        selectedPhotos
                    }
                    if !model.successfulResults.isEmpty && !model.isBusy {
                        convertButton
                    }
                    footer
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)
                .padding(.bottom, 30)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .background(AppTheme.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .tint(AppTheme.teal)
            .sheet(item: $customSetting) { setting in
                NumberSettingView(
                    setting: setting,
                    initialValue: setting == .size ? targetKB : maxLongEdge,
                    onCommit: { value in
                        switch setting {
                        case .size: targetKB = value
                        case .dimensions: maxLongEdge = value
                        }
                    }
                )
            }
            .sheet(item: $sharePayload) { payload in
                ActivityView(items: payload.urls)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showsAbout) {
                AboutView()
            }
            .alert(item: $model.banner) { notice in
                Alert(
                    title: Text(notice.title),
                    message: Text(notice.message),
                    dismissButton: .default(Text("확인"))
                )
            }
            .confirmationDialog("선택한 사진을 모두 비울까요?", isPresented: $showsClearConfirmation, titleVisibility: .visible) {
                Button("모두 비우기", role: .destructive) {
                    model.clearAll()
                    selectedItems = []
                }
            } message: {
                Text("원본 사진과 이미 저장한 사진은 그대로 남아요.")
            }
            .onChange(of: selectedItems) { _, items in
                guard !items.isEmpty else { return }
                Task {
                    await model.importPhotos(items)
                    selectedItems = []
                }
            }
            .onChange(of: targetKB) { _, _ in
                model.invalidateResults()
            }
            .onChange(of: maxLongEdge) { _, _ in
                model.invalidateResults()
            }
        }
        .preferredColorScheme(.light)
    }

    private var brandHeader: some View {
        HStack(spacing: 9) {
            Image(systemName: "arrow.down.right.and.arrow.up.left")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.teal)
                .frame(width: 32, height: 32)
                .background(AppTheme.lime)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)
            Text("딱사진")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)
            Spacer()
            Button {
                showsAbout = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(AppTheme.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("딱사진 소개 및 개인정보 안내")
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("사진을,\n딱 맞게.")
                .font(.system(size: heroFontSize, weight: .bold, design: .rounded))
                .tracking(-1.7)
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("사진을, 딱 맞게.")
            Text("용량과 크기를 맞춰 바로 저장하세요.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondary)
            Label("사진은 이 기기 안에서만 처리해요", systemImage: "checkmark.shield")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(AppTheme.teal)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.lime.opacity(0.8))
                .clipShape(Capsule())
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 3)
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 12) {
                settingHeading(number: "01", title: "최대 용량", value: "\(targetKB.formatted()) KB 이하")
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { sizeOptions }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            presetButton(label: "200 KB", isSelected: targetKB == 200) { targetKB = 200 }
                            presetButton(label: "500 KB", isSelected: targetKB == 500) { targetKB = 500 }
                        }
                        HStack(spacing: 8) {
                            presetButton(label: "1 MB", isSelected: targetKB == 1_000) { targetKB = 1_000 }
                            customSizeButton
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) { sizeOptions }
                }
            }
            Rectangle()
                .fill(AppTheme.line)
                .frame(height: 1)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 12) {
                settingHeading(number: "02", title: "긴 변의 최대 길이", value: maxLongEdge == 0 ? "자동" : "\(maxLongEdge.formatted()) px")
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { dimensionOptions }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            presetButton(label: "자동", isSelected: maxLongEdge == 0) { maxLongEdge = 0 }
                            presetButton(label: "1080 px", isSelected: maxLongEdge == 1_080) { maxLongEdge = 1_080 }
                        }
                        HStack(spacing: 8) {
                            presetButton(label: "1920 px", isSelected: maxLongEdge == 1_920) { maxLongEdge = 1_920 }
                            customDimensionsButton
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) { dimensionOptions }
                }
                Text("비율을 유지하며 줄여요. 작은 사진은 늘리지 않아요.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .cardSurface()
        .disabled(model.isBusy)
        .opacity(model.isBusy ? 0.65 : 1)
    }

    private func settingHeading(number: String, title: String, value: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(number).font(.system(.caption, design: .monospaced)).foregroundStyle(AppTheme.teal)
                Text(title).font(.system(.subheadline, design: .rounded, weight: .semibold)).foregroundStyle(AppTheme.ink)
                Spacer(minLength: 8)
                Text(value).font(.caption).foregroundStyle(AppTheme.secondary)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.system(.subheadline, design: .rounded, weight: .semibold)).foregroundStyle(AppTheme.ink)
                Text(value).font(.caption).foregroundStyle(AppTheme.secondary)
            }
        }
    }

    @ViewBuilder private var sizeOptions: some View {
        presetButton(label: "200 KB", isSelected: targetKB == 200) { targetKB = 200 }
        presetButton(label: "500 KB", isSelected: targetKB == 500) { targetKB = 500 }
        presetButton(label: "1 MB", isSelected: targetKB == 1_000) { targetKB = 1_000 }
        customSizeButton
    }

    @ViewBuilder private var dimensionOptions: some View {
        presetButton(label: "자동", isSelected: maxLongEdge == 0) { maxLongEdge = 0 }
        presetButton(label: "1080 px", isSelected: maxLongEdge == 1_080) { maxLongEdge = 1_080 }
        presetButton(label: "1920 px", isSelected: maxLongEdge == 1_920) { maxLongEdge = 1_920 }
        customDimensionsButton
    }

    private var customSizeButton: some View {
        presetButton(label: "직접 입력", isSelected: ![200, 500, 1_000].contains(targetKB)) {
            customSetting = .size
        }
    }

    private var customDimensionsButton: some View {
        presetButton(label: "직접 입력", isSelected: ![0, 1_080, 1_920].contains(maxLongEdge)) {
            customSetting = .dimensions
        }
    }

    private func presetButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(.caption, design: .rounded, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .white : AppTheme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .frame(minHeight: 44)
                .background(isSelected ? AppTheme.teal : AppTheme.canvas)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var emptySelection: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppTheme.lime)
                    .frame(width: 72, height: 81)
                    .rotationEffect(.degrees(-9))
                RoundedRectangle(cornerRadius: 18)
                    .fill(.white)
                    .frame(width: 72, height: 81)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18).stroke(AppTheme.line, lineWidth: 1)
                    }
                    .rotationEffect(.degrees(6))
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 29, weight: .light))
                    .foregroundStyle(AppTheme.teal)
            }
            .padding(.top, 9)
            .accessibilityHidden(true)
            VStack(spacing: 6) {
                Text("먼저, 사진을 골라주세요")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text("한 번에 최대 20장 · 원본은 그대로")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
            }
            photoPicker {
                Label("사진 선택", systemImage: "plus")
            }
            .buttonStyle(FilledActionStyle())
        }
        .padding(23)
        .frame(maxWidth: .infinity)
        .background(AppTheme.canvas)
        .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .strokeBorder(AppTheme.line, style: StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
        }
    }

    private func photoPicker<LabelView: View>(@ViewBuilder label: () -> LabelView) -> some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: 20,
            matching: .images,
            preferredItemEncoding: .current,
            label: label
        )
        .disabled(model.isBusy)
    }

    private var selectedPhotos: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("선택한 사진")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text("\(model.photos.count)")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.teal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.lime)
                    .clipShape(Capsule())
                Spacer()
                Button { showsClearConfirmation = true } label: {
                    Text("비우기")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                    .disabled(model.isBusy)
            }
            VStack(spacing: 0) {
                ForEach(Array(model.photos.enumerated()), id: \.element.id) { index, photo in
                    PhotoRow(
                        photo: photo,
                        number: index + 1,
                        isBusy: model.isBusy,
                        onSave: { model.savePhoto(id: photo.id) },
                        onShare: {
                            guard let result = photo.result else { return }
                            sharePayload = SharePayload(urls: [result.url])
                        }
                    )
                    if index < model.photos.count - 1 {
                        Rectangle().fill(AppTheme.line).frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, 17)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(AppTheme.line, lineWidth: 1)
            }
            photoPicker {
                Label("사진 다시 선택", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(AppTheme.teal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ProgressView().tint(AppTheme.teal)
                Text(model.currentStatus)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .accessibilityAddTraits(.updatesFrequently)
                Spacer(minLength: 0)
            }
            if model.phase == .converting {
                ProgressView(value: Double(model.completedCount), total: Double(max(1, model.photos.count)))
                    .tint(AppTheme.teal)
                HStack {
                    Text("\(model.completedCount) / \(model.photos.count)장")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                    Spacer()
                    Button("중단") { model.cancelConversion() }
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(AppTheme.teal)
                        .padding(.vertical, 8)
                }
            }
        }
        .cardSurface()
    }

    private var resultsCard: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.teal)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(model.successfulResults.count)장, 딱 맞췄어요")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text("저장하거나 원하는 앱으로 공유하세요.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("총 용량")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
                Text(AppTheme.bytes(model.totalResultBytes))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.teal)
            }
            Text("원본 \(AppTheme.bytes(successfulOriginalBytes)) → 변환 \(AppTheme.bytes(model.totalResultBytes))")
                .font(.caption)
                .foregroundStyle(AppTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 9) {
                Button {
                    model.saveAll()
                } label: {
                    Label(allResultsSaved ? "사진 앱에 저장 완료" : "모두 사진 앱에 저장", systemImage: allResultsSaved ? "checkmark" : "square.and.arrow.down")
                }
                .buttonStyle(FilledActionStyle())
                .disabled(allResultsSaved)
                .opacity(allResultsSaved ? 0.6 : 1)
                Button {
                    sharePayload = SharePayload(urls: model.successfulResults.map(\.url))
                } label: {
                    Label("모두 공유", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(FilledActionStyle(prominent: false))
            }
            .disabled(model.isBusy)
            .opacity(model.isBusy ? 0.6 : 1)
        }
        .cardSurface()
    }

    private var allResultsSaved: Bool {
        let completedPhotos = model.photos.filter { $0.result != nil }
        return !completedPhotos.isEmpty && completedPhotos.allSatisfy(\.saved)
    }

    private var successfulOriginalBytes: Int {
        model.photos.filter { $0.result != nil }.reduce(0) { $0 + $1.info.byteCount }
    }

    private var convertButton: some View {
        Button {
            model.convert(settings: settings)
        } label: {
            Label(model.successfulResults.isEmpty ? "\(model.photos.count)장 용량 맞추기" : "다시 용량 맞추기", systemImage: "arrow.down.right.and.arrow.up.left")
        }
        .buttonStyle(FilledActionStyle(prominent: model.successfulResults.isEmpty))
        .disabled(!model.canConvert)
        .opacity(model.canConvert ? 1 : 0.6)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("JPG로 변환 · 위치 정보 제거")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(AppTheme.teal)
            Text("용량 제한을 맞추기 위해 사진 크기가 줄어들 수 있어요.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 3)
    }
}

private struct PhotoRow: View {
    let photo: PreparedPhoto
    let number: Int
    let isBusy: Bool
    let onSave: () -> Void
    let onShare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 13) {
                thumbnail
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text("사진 \(number)")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                        if photo.saved {
                            Label("저장됨", systemImage: "checkmark")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.teal)
                        }
                    }
                    Text("원본 \(AppTheme.bytes(photo.info.byteCount))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                    Text("\(AppTheme.dimensions(width: photo.info.width, height: photo.info.height)) px")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondary)
                    if let result = photo.result {
                        Text("변환 \(AppTheme.bytes(result.byteCount))")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(AppTheme.teal)
                        Text("\(AppTheme.dimensions(width: result.width, height: result.height)) px · JPG")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let error = photo.error {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(AppTheme.error)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if photo.result != nil {
                HStack(spacing: 20) {
                    Button(action: onSave) {
                        Label(photo.saved ? "저장됨" : "저장", systemImage: photo.saved ? "checkmark" : "square.and.arrow.down")
                            .frame(minWidth: 64, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .disabled(photo.saved)
                    Button(action: onShare) {
                        Label("공유", systemImage: "square.and.arrow.up")
                            .frame(minWidth: 64, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                }
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.teal)
                .padding(.vertical, 5)
                .disabled(isBusy)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("사진 \(number) 작업")
            }
        }
        .padding(.vertical, 17)
    }

    private var thumbnail: some View {
        Group {
            if let thumbnail = photo.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    AppTheme.canvas
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(AppTheme.secondary)
                }
            }
        }
        .frame(width: 66, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityHidden(true)
    }
}

struct SharePayload: Identifiable {
    let id = UUID()
    let urls: [URL]
}
