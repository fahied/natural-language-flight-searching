# NLFlightSearching

NLFlightSearching is a lightweight Swift framework for recognizing flight search information from spoken queries. It combines `SFSpeechRecognizer` for speech to text and Apple's NaturalLanguage framework with a custom tagger to extract locations and dates.

## Usage

1. Add the `NLFlightSearching` framework to your Xcode project.
2. Include the compiled CoreML model `FlightsTagger.mlmodelc` in the framework bundle (see below).
3. Create an instance of `NLFlightSearching` and implement `NLFlightSearchingDelegate` to receive updates.

```swift
import NLFlightSearching

class ViewController: UIViewController, NLFlightSearchingDelegate {
    var flightSearching: NLFlightSearching?

    override func viewDidLoad() {
        super.viewDidLoad()
        flightSearching = try? NLFlightSearching(locale: Locale.current)
        flightSearching?.delegate = self
    }

    func start() throws { try flightSearching?.beginSpeechRecordering() }
    func stop() { flightSearching?.stopSpeechRecordering() }

    // NLFlightSearchingDelegate
    func flightSearching(_ flightSearching: NLFlightSearching,
                         speechHandlerStatusDidChangeTo status: SpeechHandlerStatus) {}
    func flightSearching(_ flightSearching: NLFlightSearching,
                         speechRecognized text: String) {}
    func flightSearchingDidEndRecognizing(_ flightSearching: NLFlightSearching,
                                          speechRecognized text: String,
                                          extractedKeywords: [NLFlightSearchingTag:[String]]) {}
}
```

## Example Application

An example iOS application is provided in `NLFlightSearchingExample`. Open
`NLFlightSearching.xcworkspace` in Xcode, select the
`NLFlightSearchingExample` scheme and run it on a device or simulator. Tap the
"Speak" button to start or stop speech recognition. Extracted keywords will be
shown in the dialog view.

## FlightsTagger.mlmodel

The taggers rely on a CoreML model named `FlightsTagger.mlmodel`. The model is
not included in this repository. Train or obtain a model that can recognize
origin, destination and date phrases in flight search queries using Create ML or
another tool. After training, compile the model with:

```bash
xcrun coremlc compile /path/to/FlightsTagger.mlmodel /path/to/NLFlightSearching
```

Copy the resulting `FlightsTagger.mlmodelc` directory into the
`NLFlightSearching` folder so it is bundled with the framework during the
build.

## Training with PyTorch

A simple Python script is provided in `scripts/train_flight_ner.py` to demonstrate how you could train a token classification model with PyTorch and the Hugging Face `transformers` library. The script generates synthetic sentences with sample origins, destinations and dates. After training, export the model and convert it to Core ML using `coremltools` if needed.

