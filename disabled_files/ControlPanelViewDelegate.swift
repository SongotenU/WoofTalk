// MARK: - ControlPanelViewDelegate

protocol ControlPanelViewDelegate: AnyObject {
    func controlPanelDidTapTranslate(_ view: ControlPanelView)
    func controlPanelDidTapSettings(_ view: ControlPanelView)
    func controlPanelDidTapHelp(_ view: ControlPanelView)
}