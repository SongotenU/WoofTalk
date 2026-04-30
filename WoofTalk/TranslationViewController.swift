import UIKit

/// Simplified translation display and user feedback interface
final class TranslationViewController: UIViewController {

    private let translationView = TranslationView()
    private let translationEngine = TranslationEngine()
    private var translationHistory: [TranslationRecord] = []

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Translate"

        translationView.delegate = self
        translationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(translationView)

        NSLayoutConstraint.activate([
            translationView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            translationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            translationView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            translationView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
}

extension TranslationViewController: TranslationViewDelegate {
    func translationViewDidTapTranslate(_ view: TranslationView) {
        let input = "hello"
        do {
            let result = try translationEngine.translate(input, direction: .humanToDog)
            translationView.updateInputText(input)
            translationView.updateTranslatedText(result)
            translationView.updateStatus("Translated successfully")
            translationHistory.insert(TranslationRecord(humanText: input, dogTranslation: result, timestamp: Date()), at: 0)
        } catch {
            translationView.updateStatus("Translation failed: \(error.localizedDescription)")
        }
    }

    func translationViewDidTapClear(_ view: TranslationView) {
        translationView.updateInputText("")
        translationView.updateTranslatedText("")
        translationView.updateStatus("Ready to translate")
        translationHistory.removeAll()
    }

    func translationViewDidTapHistory(_ view: TranslationView) {
        let historyVC = TranslationHistoryViewController(translationHistory: translationHistory)
        navigationController?.pushViewController(historyVC, animated: true)
    }
}

struct TranslationRecord: Codable {
    let humanText: String
    let dogTranslation: String
    let timestamp: Date
}
