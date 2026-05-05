# WoofTalk Privacy Policy

**Effective Date:** 2026-05-05  
**Last Updated:** 2026-05-05

## Introduction

WoofTalk ("we," "our," or "us") respects your privacy and is committed to protecting your personal data. This Privacy Policy explains how we collect, use, and share information when you use our mobile apps (iOS, Android, Wear OS) and web application (collectively, the "Service").

## Information We Collect

### Information You Provide
- **Account Information**: Email address, username, profile photo (if provided)
- **Translation History**: Text and voice inputs you submit for translation
- **Community Content**: Phrases you submit, comments, votes
- **Subscription Data**: Purchase history via RevenueCat (we do NOT store payment card details)

### Information Collected Automatically
- **Device Information**: Device type, OS version, app version
- **Usage Data**: Features used, translation count, session duration
- **Crash Reports**: Error logs via Sentry (iOS/Web) and Firebase Crashlytics (Android)
- **Performance Metrics**: App launch time, API latency (Firebase Performance)

### Information from Third Parties
- **Authentication Providers**: Google, Apple (if you sign in with these services)
- **RevenueCat**: Subscription status, purchase history
- **Supabase**: Authentication tokens, database records

## How We Use Your Information

We use your information to:
1. **Provide the Service**: Process translations, sync across devices, display your history
2. **Improve the Service**: Analyze usage patterns, fix bugs, add features
3. **Communicate with You**: Send push notifications (if enabled), respond to support requests
4. **Ensure Security**: Detect fraud, abuse, or violations of our Terms
5. **Process Payments**: Manage subscriptions via RevenueCat (we never see your card details)

## Data Sharing

We share your information only as described below:
- **Supabase**: Database hosting, authentication, real-time sync
- **RevenueCat**: Subscription management and receipt validation
- **Firebase (Google)**: Crash reporting, performance monitoring, push notifications
- **Sentry**: Error tracking and performance monitoring
- **Legal Requirements**: If required by law or to protect our rights

We do NOT sell your personal information to third parties.

## Data Retention

- **Account Data**: Retained until you delete your account
- **Translation History**: Retained until you delete your account or individual entries
- **Community Phrases**: Retained until you delete them or we remove inappropriate content
- **Crash Logs**: Retained for 30 days (Sentry/Crashlytics)
- **Usage Analytics**: Aggregated data may be retained indefinitely

## Your Rights (GDPR/CCPA)

Depending on your location, you may have the right to:
- **Access**: Request a copy of your personal data
- **Rectification**: Correct inaccurate or incomplete data
- **Erasure**: Request deletion of your personal data ("Right to be Forgotten")
- **Portability**: Receive your data in a structured, machine-readable format
- **Opt-Out**: Decline marketing communications and certain data sharing

To exercise these rights, contact us at **privacy@wooftalk.app**.

## Children's Privacy

The Service is not intended for children under 13 (or 16 in some jurisdictions). We do not knowingly collect personal information from children. If you believe a child has provided us information, contact us to have it removed.

## Data Security

We implement appropriate technical and organizational measures to protect your data:
- Encryption in transit (TLS 1.3) and at rest (AES-256)
- Row-Level Security (RLS) policies in Supabase
- JWT-based authentication with Supabase Auth
- Regular security audits and dependency updates

## International Transfers

Your data may be processed in the United States (where Supabase, RevenueCat, and Firebase servers are located). By using the Service, you consent to this transfer.

## Changes to This Policy

We may update this Privacy Policy from time to time. We will notify you of material changes via:
- In-app notification
- Email (if provided)
- App Store/Play Store update notes

The "Last Updated" date at the top indicates when the policy was last revised.

## Contact Us

For questions about this Privacy Policy:
- **Email**: privacy@wooftalk.app
- **Mail**: WoofTalk Privacy Team, [Your Address]

---

## Quick Reference

| Data Type | Stored By | Retention |
|-----------|-----------|-----------|
| Email, Username | Supabase Auth | Until account deletion |
| Translation History | Supabase DB | Until deletion |
| Crash Reports | Sentry/Crashlytics | 30 days |
| Subscription Data | RevenueCat | Per their policy |
| Usage Analytics | Firebase/Supabase | Aggregated: indefinite |
