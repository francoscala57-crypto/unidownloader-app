import SwiftUI
import Foundation
import UniformTypeIdentifiers

#if os(iOS)
import UIKit
#endif

struct ContentView: View {
    @State private var urlString = ""
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    @State private var downloadedFiles: [DownloadedFile] = []
    @State private var selectedFile: DownloadedFile?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var downloadManager: DownloadManager?
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.15, blue: 0.3),
                    Color(red: 0.2, green: 0.1, blue: 0.25)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                ScrollView {
                    VStack(spacing: 20) {
                        urlInputSection
                        downloadButton
                        infoSection
                        
                        if !downloadedFiles.isEmpty {
                            downloadedFilesSection
                        }
                        
                        Spacer()
                            .frame(height: 20)
                    }
                }
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            setupDownloadManager()
        }
    }
    
    private func setupDownloadManager() {
        if downloadManager == nil {
            downloadManager = DownloadManager()
            downloadManager?.delegate = DownloadViewDelegate(
                onProgress: { progress in
                    DispatchQueue.main.async {
                        self.downloadProgress = progress
                    }
                },
                onCompletion: { url, fileName in
                    DispatchQueue.main.async {
                        let newFile = DownloadedFile(
                            id: UUID(),
                            name: fileName,
                            size: getFileSize(url),
                            date: Date(),
                            url: url
                        )
                        self.downloadedFiles.insert(newFile, at: 0)
                        self.isDownloading = false
                        self.downloadProgress = 0
                        self.urlString = ""
                        self.showAlert(title: "Successo", message: "File scaricato correttamente!")
                    }
                },
                onError: { error in
                    DispatchQueue.main.async {
                        self.isDownloading = false
                        self.downloadProgress = 0
                        self.showAlert(title: "Errore", message: error)
                    }
                }
            )
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.cyan)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("UniDownloader")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                    Text("Scarica qualunque contenuto dal web")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding()
            
            Divider()
                .background(Color.gray.opacity(0.3))
        }
        .background(Color.black.opacity(0.3))
    }
    
    private var urlInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Inserisci URL", systemImage: "link")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)
            
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(.cyan)
                
                TextField("https://example.com/file.zip", text: $urlString)
                    .disableAutocorrection(true)
                    .foregroundColor(.white)
                
                if !urlString.isEmpty {
                    Button(action: { urlString = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
    
    private var downloadButton: some View {
        Button(action: {
            startDownload()
        }) {
            if isDownloading {
                HStack(spacing: 12) {
                    ProgressView(value: downloadProgress)
                        .tint(.cyan)
                        .frame(width: 60)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scaricamento in corso...")
                            .font(.system(.body, design: .rounded))
                        Text("\(Int(downloadProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("Scarica")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .foregroundColor(.white)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.cyan,
                    Color.blue
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
        .padding(.horizontal)
        .disabled(urlString.isEmpty || isDownloading)
        .opacity(urlString.isEmpty || isDownloading ? 0.6 : 1.0)
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tipi di file supportati", systemImage: "doc.badge.gearshape")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                fileTypeTagView("📄", "Documenti", "PDF, DOCX, TXT, XLS")
                fileTypeTagView("🎵", "Audio", "MP3, WAV, M4A, AAC")
                fileTypeTagView("🎬", "Video", "MP4, MOV, AVI, MKV")
                fileTypeTagView("🖼️", "Immagini", "JPG, PNG, GIF, WEBP")
                fileTypeTagView("📦", "Archivi", "ZIP, RAR, 7Z, TAR")
                fileTypeTagView("💾", "Software", "APK, APP, EXE, DMG")
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var downloadedFilesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("File Scaricati", systemImage: "folder.fill")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(downloadedFiles.count)")
                    .font(.caption)
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cyan.opacity(0.2))
                    .cornerRadius(6)
            }
            
            VStack(spacing: 10) {
                ForEach(downloadedFiles, id: \.id) { file in
                    DownloadedFileRow(file: file, onDelete: {
                        downloadedFiles.removeAll { $0.id == file.id }
                    })
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func fileTypeTagView(_ emoji: String, _ title: String, _ types: String) -> some View {
        HStack(spacing: 10) {
            Text(emoji)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.cyan)
                
                Text(types)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color.cyan.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func startDownload() {
        guard !urlString.isEmpty else {
            showAlert(title: "Errore", message: "Inserisci un URL")
            return
        }
        
        guard let url = URL(string: urlString) else {
            showAlert(title: "URL Non Valido", message: "Inserisci un URL valido (es: https://...)")
            return
        }
        
        isDownloading = true
        downloadProgress = 0
        
        if downloadManager == nil {
            setupDownloadManager()
        }
        
        downloadManager?.download(from: url)
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Download Manager
class DownloadManager: NSObject, URLSessionDownloadDelegate {
    var delegate: DownloadDelegate?
    var activeDownloads: [String: Download] = [:]
    var session: URLSession?
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.unidownloader.background")
        config.waitsForConnectivity = true
        config.shouldUseExtendedBackgroundIdleMode = true
        session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
    }
    
    func download(from url: URL) {
        print("🔄 Inizio download da: \(url.absoluteString)")
        let downloadTask = session?.downloadTask(with: url)
        let download = Download(url: url)
        activeDownloads[url.absoluteString] = download
        downloadTask?.resume()
        print("✅ Download task avviato")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let url = downloadTask.currentRequest?.url else {
            print("❌ Errore: URL non trovato")
            delegate?.downloadDidFail(error: "Errore: URL non trovato")
            return
        }
        
        print("✅ Download completato da: \(url.absoluteString)")
        
        let fileName = getFileName(from: url, response: downloadTask.response as? HTTPURLResponse)
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent(fileName)
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.moveItem(at: location, to: destinationURL)
            activeDownloads.removeValue(forKey: url.absoluteString)
            print("💾 File salvato in: \(destinationURL.path)")
            delegate?.downloadDidFinish(fileURL: destinationURL, fileName: fileName)
        } catch {
            print("❌ Errore nel salvataggio: \(error)")
            delegate?.downloadDidFail(error: "Errore nel salvataggio del file: \(error.localizedDescription)")
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            print("📊 Progresso: \(Int(progress * 100))%")
            delegate?.downloadDidProgress(progress: progress)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else { return }
        print("❌ Errore download: \(error.localizedDescription)")
        delegate?.downloadDidFail(error: error.localizedDescription)
    }
}

// MARK: - Download Model
struct Download {
    let url: URL
    var progress: Double = 0
}

// MARK: - Download Delegate
protocol DownloadDelegate {
    func downloadDidProgress(progress: Double)
    func downloadDidFinish(fileURL: URL, fileName: String)
    func downloadDidFail(error: String)
}

// MARK: - Download View Delegate
class DownloadViewDelegate: DownloadDelegate {
    var onProgress: ((Double) -> Void)?
    var onCompletion: ((URL, String) -> Void)?
    var onError: ((String) -> Void)?
    
    init(onProgress: ((Double) -> Void)? = nil, onCompletion: ((URL, String) -> Void)? = nil, onError: ((String) -> Void)? = nil) {
        self.onProgress = onProgress
        self.onCompletion = onCompletion
        self.onError = onError
    }
    
    func downloadDidProgress(progress: Double) {
        onProgress?(progress)
    }
    
    func downloadDidFinish(fileURL: URL, fileName: String) {
        onCompletion?(fileURL, fileName)
    }
    
    func downloadDidFail(error: String) {
        onError?(error)
    }
}

// MARK: - Helper Models
struct DownloadedFile: Identifiable {
    let id: UUID
    let name: String
    let size: String
    let date: Date
    let url: URL
}

// MARK: - Downloaded File Row
struct DownloadedFileRow: View {
    let file: DownloadedFile
    let onDelete: () -> Void
    @State private var showShareSheet = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: getFileIcon(file.name))
                .font(.system(size: 20))
                .foregroundColor(.cyan)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(file.size)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(formatDate(file.date))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Menu {
                Button(action: { showShareSheet = true }) {
                    Label("Condividi", systemImage: "square.and.arrow.up")
                }
                
                Button(action: onDelete) {
                    Label("Elimina", systemImage: "trash")
                        .foregroundColor(.red)
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .foregroundColor(.cyan)
                    .font(.system(size: 20))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
        .sheet(isPresented: $showShareSheet) {
            #if os(iOS)
            ShareSheetController(items: [file.url])
            #endif
        }
    }
}

// MARK: - Share Sheet
#if os(iOS)
struct ShareSheetController: UIViewControllerRepresentable {
    let items: [URL]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareSheetController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            presentationMode.wrappedValue.dismiss()
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareSheetController>) {
    }
}
#endif

// MARK: - Utility Functions
func getFileName(from url: URL, response: HTTPURLResponse?) -> String {
    if let contentDisposition = response?.allHeaderFields["content-disposition"] as? String,
       let range = contentDisposition.range(of: "filename=") {
        let filename = String(contentDisposition[range.upperBound...])
            .replacingOccurrences(of: "\"", with: "")
            .split(separator: ";")
            .first.map(String.init) ?? url.lastPathComponent
        return filename
    }
    
    let fileName = url.lastPathComponent
    return fileName.isEmpty ? "download_\(Date().timeIntervalSince1970).bin" : fileName
}

func getFileSize(_ url: URL) -> String {
    do {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        if let size = attributes[.size] as? NSNumber {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
            formatter.countStyle = .file
            return formatter.string(fromByteCount: size.int64Value)
        }
    } catch { }
    return "N/A"
}

func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    formatter.locale = Locale(identifier: "it_IT")
    return formatter.string(from: date)
}

func getFileIcon(_ fileName: String) -> String {
    let ext = (fileName as NSString).pathExtension.lowercased()
    
    let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp", "bmp", "svg"]
    let videoExtensions = ["mp4", "mov", "avi", "mkv", "flv", "wmv", "webm"]
    let audioExtensions = ["mp3", "wav", "m4a", "aac", "flac", "wma"]
    let documentExtensions = ["pdf", "doc", "docx", "txt", "xls", "xlsx", "ppt", "pptx"]
    let archiveExtensions = ["zip", "rar", "7z", "tar", "gz", "bz2"]
    
    if imageExtensions.contains(ext) {
        return "photo.fill"
    } else if videoExtensions.contains(ext) {
        return "film.fill"
    } else if audioExtensions.contains(ext) {
        return "music.note"
    } else if documentExtensions.contains(ext) {
        return "doc.fill"
    } else if archiveExtensions.contains(ext) {
        return "archivebox.fill"
    } else {
        return "doc.fill"
    }
}

#Preview {
    ContentView()
}
