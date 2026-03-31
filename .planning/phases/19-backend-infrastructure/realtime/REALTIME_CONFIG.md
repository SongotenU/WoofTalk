# Realtime Configuration

## Enable Realtime on Tables

1. Go to Supabase Dashboard → Database → Replication
2. Toggle "Enable Realtime" for: `community_phrases`, `activity_events`, `leaderboard_entries`

## Broadcast Channels

### phrase_updates
- **Source:** `community_phrases`
- **Filter:** `approval_status = 'approved'`
- **Events:** INSERT, UPDATE

### activity_feed
- **Source:** `activity_events`
- **Filter:** `visibility = 'public'`
- **Events:** INSERT

### leaderboard_changes
- **Source:** `leaderboard_entries`
- **Events:** UPDATE

## Latency Testing

1. Start listening in client
2. Insert a row via SQL editor
3. Measure time until event received
4. Target: < 1 second
