// MARK: - TranslationViewDelegate

protocol TranslationViewDelegate: AnyObject {
    func translationViewDidTapTranslate(_ view: TranslationView)
    func translationViewDidTapClear(_ view: TranslationView)
    func translationViewDidTapHistory(_ view: TranslationView)
}