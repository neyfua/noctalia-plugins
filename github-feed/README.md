# GitHub Feed Plugin for Noctalia

Plugin that displays your GitHub activity feed, similar to the GitHub dashboard. Shows activity from people you follow and stars/forks on your repositories.

## Features

- Activity from users you follow (stars, forks, PRs, issues, comments, releases)
- Stars and forks on your own repositories
- Cached avatars
- Configurable refresh interval
- Event type filtering

## Installation

Copy the `github-feed` folder to your noctalia plugins directory:

```
~/.config/noctalia/plugins/github-feed/
```

## Configuration

Open the plugin settings in noctalia to configure:

- **Username**: Your GitHub username (required)
- **Token**: Personal access token for higher rate limits (optional but recommended)
- **Refresh Interval**: How often to check for new events
- **Event Types**: Toggle which events to show

### Getting a Token

Without a token, GitHub limits you to 60 API requests per hour. With a token, you get 5000.

1. Go to https://github.com/settings/tokens
2. Generate new token (classic)
3. No special permissions needed
4. Copy the token to the plugin settings

## API Usage

The plugin makes around 11 API calls per refresh:

- 1 call for your following list
- 3 calls for received_events (pages 1-3, up to 300 events)
- 1 call for your repos list
- 5 calls for events on your top 5 repos (to catch stars/forks)
- Avatar downloads only happen once per user

With the 30 minute default refresh interval and a token, you will never hit rate limits.

## How it Works

### Fetching Events

The plugin uses GitHub's `received_events` endpoint which returns events from:

- Repositories you watch/star
- Users you follow

Since this endpoint returns a lot of noise (random people starring repos you watch), the plugin:

1. Fetches your following list
2. Fetches 3 pages of received_events (300 events max)
3. Filters to only show events where the actor is someone you follow
4. Separately fetches stars/forks on your own repos

### Main.qml Structure

```javascript
// Key properties
property var events: []              // Final filtered events
property var receivedEvents: []      // Raw events from API
property var followingList: []       // Lowercase usernames you follow
property var myRepoEvents: []        // Stars/forks on your repos

// Fetch flow
fetchFromGitHub()
  -> followingProcess (get following list)
  -> receivedEventsProcess (get events, paginated)
  -> userReposProcess -> repoEventsProcess (get activity on your repos)
  -> finalizeFetch() (filter and merge)
```

### Filtering Logic

```javascript
// Build set of followed usernames for fast lookup
var followingSet = {}
for (var i = 0; i < root.followingList.length; i++) {
    followingSet[root.followingList[i]] = true
}

// Only keep events from people you follow
var filtered = root.receivedEvents.filter(function(event) {
    var actorLogin = event.actor.login.toLowerCase()
    return followingSet[actorLogin] === true
})
```

### Caching

Events are cached to `cache/events.json` with a timestamp. On startup, cached data is used if it's younger than the refresh interval.

Avatars are downloaded once to `cache/avatars/{user_id}.png` and reused.

## IPC Commands

Trigger actions from the command line:

```bash
# Refresh the feed
qs -c noctalia ipc call plugin:github-feed refresh

# Toggle the panel
qs -c noctalia ipc call plugin:github-feed toggle

# Set username
qs -c noctalia ipc call plugin:github-feed setUsername "your-username"
```

## Files

```
github-feed/
  manifest.json      # Plugin metadata
  Main.qml           # Core logic, API fetching, caching
  BarWidget.qml      # Bar button (GitHub icon)
  Panel.qml          # Popup panel with event list
  Settings.qml       # Configuration UI
  settings.json      # User settings
  cache/
    events.json      # Cached events
    avatars/         # Cached user avatars
```
