# Feature Research

**Domain:** M006 Enterprise — API Access, Admin Dashboard, Team/Org Management
**Researched:** 2026-04-02
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Must Have)

Users building enterprise products expect these. Missing = non-starter.

#### API Access
| Feature | Why Expected | Complexity |
|---------|--------------|------------|
| API key generation/revocation | Basic credential management | LOW |
| Per-key rate limiting | Prevent abuse, fair usage | MEDIUM |
| Usage dashboard (requests/day) | Visibility into API consumption | MEDIUM |
| Key scoping (read-only, translate-only) | Principle of least privilege | MEDIUM |
| Key naming | Identify which integration uses which key | LOW |

#### Admin Dashboard
| Feature | Why Expected | Complexity |
|---------|--------------|------------|
| User list with search/filter | Basic user management | LOW |
| Role management (admin/moderator flags) | Content moderation delegation | MEDIUM |
| Content moderation queue | Review reported phrases/users | MEDIUM |
| Ban/suspend user | Safety enforcement | LOW |
| Basic audit log | Who did what, when | MEDIUM |
| Bulk actions | Efficient moderation | MEDIUM |

#### Organization Management
| Feature | Why Expected | Complexity |
|---------|--------------|------------|
| Create organization | Top-level entity | LOW |
| Invite members by email | Onboarding workflow | MEDIUM |
| Role hierarchy (Owner/Admin/Member/Viewer) | Access control granularity | HIGH |
| Remove/transfer ownership | Lifecycle management | MEDIUM |
| Shared API key pool (org-level keys) | Team-wide access | MEDIUM |

### Differentiators (Nice to Have)
| Feature | Value | Complexity |
|---------|-------|------------|
| Per-key usage alerts (email/webhook) | Proactive management | MEDIUM |
| IP allowlisting per key | Extra security layer | LOW |
| API playground (interactive docs) | Developer experience | MEDIUM |
| Automated spam detection for enterprise content | Content quality at scale | HIGH |
| SSO/SAML integration | Enterprise IT compliance | HIGH |
| Usage-based billing tiers | Flexible pricing model | HIGH |
| Team workspaces | Org-level content separation | HIGH |
| Custom translation packs per org | Domain-specific translations | HIGH |

### Anti-Features (Avoid)
| Anti-feature | Why Bad |
|--------------|---------|
| Unlimited API keys without rate limit | Abuse vector, cost unbounded |
| Hard deletes in admin panel | No audit trail, compliance risk |
| Billing managed inside admin dashboard | Confuses roles — admin != billing admin |
| Shared user accounts | Defeats audit logging entirely |
| Auto-approve all enterprise content | Trust abuse, spam vector |
| Email invites without expiry | Security risk if email forwarded |
| Per-user custom RBAC matrixes | Unmaintainable complexity |

## Dependency Chain

```
F1 (Role/Access Foundation) → F2 (API Keys) + F3 (Admin Dashboard) in parallel
F1 (Role/Access Foundation) → F4 (Organizations) → F5 (Billing) → F6 (Org API Keys)
Paths A and B are parallel after F1
```

## Complexity Assessment

| Capabilities | Complexity | Driver |
|-------------|-----------|--------|
| API Keys + Gateway | MEDIUM | Rate limiting, secure key generation |
| Admin Dashboard | LOW-MEDIUM | CRUD + tables; existing Next.js helps |
| RBAC + Orgs | HIGH | Schema migration, RLS policy explosion |
| SSO/SAML | HIGH | Protocol complexity, IdP variations |
| Usage Billing | MEDIUM | Integration with Stripe, metered billing |
