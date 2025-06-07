import SwiftUI
import NLFlightSearching

enum RecordingStatus {
    case recording
    case ready
    case inaccessible
}

final class FlightSearchingViewModel: NSObject, ObservableObject, NLFlightSearchingDelegate {
    @Published var attributedText = NSMutableAttributedString()
    @Published var recordingStatus: RecordingStatus = .inaccessible

    private var flightSearching: NLFlightSearching?
    private var savedText = NSMutableAttributedString()

    func setup() {
        do {
            flightSearching = try NLFlightSearching(locale: Locale(identifier: "ru-RU"))
            flightSearching?.delegate = self
            switch flightSearching!.state {
            case .ready, .requiresAuthorization:
                recordingStatus = .ready
            case .recording:
                recordingStatus = .recording
            case .inaccessible:
                recordingStatus = .inaccessible
            }
            addMachine(phrase: "Здравствуйте. Нажмите на кнопку, чтобы начать поиск рейсов голосом")
        } catch {
            recordingStatus = .inaccessible
        }
    }

    func recordTapped() {
        switch recordingStatus {
        case .ready:
            do {
                savedText = attributedText.mutableCopy() as! NSMutableAttributedString
                try flightSearching?.beginSpeechRecordering()
                recordingStatus = .recording
            } catch {
                addMachine(phrase: "Кажется возникла проблема с записью речи")
            }
        case .recording:
            flightSearching?.stopSpeechRecordering()
            recordingStatus = .ready
        case .inaccessible:
            break
        }
    }

    // MARK: - NLFlightSearchingDelegate
    func flightSearching(_ flightSearching: NLFlightSearching, speechHandlerStatusDidChangeTo status: SpeechHandlerStatus) {
        switch status {
        case .ready, .requiresAuthorization:
            recordingStatus = .ready
        case .recording:
            recordingStatus = .recording
        case .inaccessible:
            recordingStatus = .inaccessible
        }
    }

    func flightSearching(_ flightSearching: NLFlightSearching, speechRecognized text: String) {
        attributedText = savedText.mutableCopy() as! NSMutableAttributedString
        addUser(phrase: text)
    }

    func flightSearchingDidEndRecognizing(_ flightSearching: NLFlightSearching, speechRecognized text: String, extractedKeywords: [NLFlightSearchingTag : [String]]) {
        extractedKeywords.forEach { tag, keywords in
            keywords.forEach { keyword in
                addMachine(phrase: "\(tag) \(keyword)")
            }
        }
    }

    // MARK: - Text handling
    private func addMachine(phrase: String) {
        var string = "\n" + phrase + "\n"
        let attrs = DialogTextViewAttributes().left.bright.attributes
        let part = NSMutableAttributedString(string: string, attributes: attrs)
        let temp = NSMutableAttributedString()
        temp.append(attributedText)
        temp.append(part)
        attributedText = temp
    }

    private func addUser(phrase: String) {
        bleachPrevious()
        var string = "\n\"" + phrase + "\"\n"
        let attrs = DialogTextViewAttributes().right.bright.attributes
        let part = NSMutableAttributedString(string: string, attributes: attrs)
        let temp = NSMutableAttributedString()
        temp.append(attributedText)
        temp.append(part)
        attributedText = temp
    }

    private func bleachPrevious() {
        let mutable = attributedText.mutableCopy() as! NSMutableAttributedString
        let range = NSRange(0..<mutable.length)
        mutable.addAttributes(DialogTextViewAttributes().left.bleached.attributes, range: range)
        attributedText = mutable
    }
}

struct DialogTextViewRepresentable: UIViewRepresentable {
    @Binding var attributedText: NSMutableAttributedString

    func makeUIView(context: Context) -> DialogTextView {
        let view = DialogTextView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: DialogTextView, context: Context) {
        uiView.attributedText = attributedText
        uiView.scrollToBottom()
    }
}

struct ContentView: View {
    @StateObject private var viewModel = FlightSearchingViewModel()

    var body: some View {
        VStack {
            DialogTextViewRepresentable(attributedText: $viewModel.attributedText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Button(action: { viewModel.recordTapped() }) {
                Text(viewModel.recordingStatus == .recording ? "Stop" : "Speak")
                    .frame(maxWidth: .infinity)
            }
            .disabled(viewModel.recordingStatus == .inaccessible)
            .padding()
        }
        .onAppear {
            viewModel.setup()
        }
    }
}
