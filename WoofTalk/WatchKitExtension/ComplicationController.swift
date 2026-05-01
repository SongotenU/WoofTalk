import ClockKit
import WatchKit

class ComplicationController: NSObject, CLKComplicationDataSource {

    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let template = createTemplate(for: complication)
        let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
        handler(entry)
    }

    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([])
    }

    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        handler(nil)
    }

    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        handler(nil)
    }

    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }

    private func createTemplate(for complication: CLKComplication) -> CLKComplicationTemplate {
        let lastTranslation = WatchTranslationStore.shared.lastTranslation()
        let text: String
        if let translation = lastTranslation {
            text = String(translation.translated.prefix(20))
        } else {
            text = "WoofTalk"
        }

        switch complication.family {
        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallSimpleText()
            template.textProvider = CLKSimpleTextProvider(text: text)
            return template

        case .modularLarge:
            let template = CLKComplicationTemplateModularLargeStandardBody()
            template.headerTextProvider = CLKSimpleTextProvider(text: "WoofTalk")
            template.body1TextProvider = CLKSimpleTextProvider(text: text)
            return template

        case .utilitarianSmall:
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            template.textProvider = CLKSimpleTextProvider(text: "🐕")
            return template

        case .utilitarianLarge:
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            template.textProvider = CLKSimpleTextProvider(text: "WoofTalk: \(text)")
            return template

        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallSimpleText()
            template.textProvider = CLKSimpleTextProvider(text: "🐕")
            return template

        case .extraLarge:
            let template = CLKComplicationTemplateExtraLargeSimpleText()
            template.textProvider = CLKSimpleTextProvider(text: "🐕")
            return template

        case .graphicCorner:
            if #available(watchOS 5.0, *) {
                let template = CLKComplicationTemplateGraphicCornerText()
                template.textProvider = CLKSimpleTextProvider(text: "WoofTalk")
                return template
            }
            return CLKComplicationTemplateModularSmallSimpleText()

        case .graphicCircular:
            if #available(watchOS 5.0, *) {
                let template = CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText()
                template.centerTextProvider = CLKSimpleTextProvider(text: "🐕")
                template.bottomTextProvider = CLKSimpleTextProvider(text: "Talk")
                return template
            }
            return CLKComplicationTemplateCircularSmallSimpleText()

        case .graphicRectangular:
            if #available(watchOS 5.0, *) {
                let template = CLKComplicationTemplateGraphicRectangularStandardBody()
                template.headerTextProvider = CLKSimpleTextProvider(text: "WoofTalk")
                template.body1TextProvider = CLKSimpleTextProvider(text: text)
                return template
            }
            return CLKComplicationTemplateModularSmallSimpleText()

        default:
            let template = CLKComplicationTemplateModularSmallSimpleText()
            template.textProvider = CLKSimpleTextProvider(text: "🐕")
            return template
        }
    }

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptor = CLKComplicationDescriptor(
            identifier: "com.wooftalk.watch",
            displayName: "WoofTalk",
            supportedFamilies: [
                .modularSmall, .modularLarge,
                .utilitarianSmall, .utilitarianLarge,
                .circularSmall, .extraLarge,
                .graphicCorner, .graphicCircular, .graphicRectangular
            ]
        )
        handler([descriptor])
    }
}
