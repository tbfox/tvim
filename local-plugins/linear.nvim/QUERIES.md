# Linear GraphQL Queries Documentation

This document contains all the GraphQL queries and mutations needed for linear.nvim, based on research from Linear's API documentation.

## API Endpoint

```
https://api.linear.app/graphql
```

## Authentication

**Header:** `Authorization: <API_KEY>`

For personal API keys, use the key directly (not Bearer token):
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: lin_api_xxxxx" \
  --data '{"query": "..."}' \
  https://api.linear.app/graphql
```

## Test Authentication Query

```graphql
query TestAuth {
  viewer {
    id
    name
    email
  }
}
```

**Usage:** Verify API key is valid and get authenticated user info.

---

## Issues Queries

### List Issues

```graphql
query ListIssues($first: Int, $filter: IssueFilter) {
  issues(first: $first, filter: $filter) {
    nodes {
      id
      identifier       # e.g., "ENG-123"
      title
      description
      state {
        id
        name          # e.g., "Todo", "In Progress", "Done"
        type          # e.g., "started", "completed"
      }
      assignee {
        id
        name
        email
      }
      project {
        id
        name
      }
      labels {
        nodes {
          id
          name
        }
      }
      dueDate        # ISO 8601 date string
      updatedAt      # ISO 8601 datetime
      createdAt
      archivedAt     # null if not archived
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
```

**Variables:**
```json
{
  "first": 50,
  "filter": {
    "state": { "type": { "eq": "started" } }
  }
}
```

**Filter options:**
- `includeArchived: true` - Include archived issues (default: false)
- `state: { type: { eq: "started" } }` - Filter by state type
- `assignee: { id: { eq: "user-id" } }` - Filter by assignee
- `team: { id: { eq: "team-id" } }` - Filter by team

### Get Single Issue

```graphql
query GetIssue($id: String!) {
  issue(id: $id) {
    id
    identifier
    title
    description
    state {
      id
      name
      type
    }
    assignee {
      id
      name
      email
    }
    project {
      id
      name
    }
    labels {
      nodes {
        id
        name
      }
    }
    dueDate
    estimate
    priority
    priorityLabel
    url             # Linear web URL
    team {
      id
      name
      key
    }
    updatedAt
    createdAt
    archivedAt
  }
}
```

**Variables:**
```json
{
  "id": "issue-uuid"
}
```

**Note:** The `id` parameter expects the UUID (e.g., from `nodes[].id`), not the identifier (e.g., "ENG-123").

---

## Issue Mutations

### Create Issue

```graphql
mutation CreateIssue($input: IssueCreateInput!) {
  issueCreate(input: $input) {
    success
    issue {
      id
      identifier
      title
      url
    }
  }
}
```

**Required Variables:**
```json
{
  "input": {
    "teamId": "team-uuid",
    "title": "Issue title"
  }
}
```

**Optional Fields in IssueCreateInput:**
- `description: String`
- `assigneeId: String` - User UUID
- `stateId: String` - Workflow state UUID
- `priority: Int` - 0 (No priority), 1 (Urgent), 2 (High), 3 (Normal), 4 (Low)
- `projectId: String` - Project UUID
- `cycleId: String` - Cycle UUID
- `parentId: String` - Parent issue UUID (for sub-issues)
- `labelIds: [String!]` - Array of label UUIDs
- `estimate: Float` - Estimate in points/hours

### Update Issue

```graphql
mutation UpdateIssue($id: String!, $input: IssueUpdateInput!) {
  issueUpdate(id: $id, input: $input) {
    success
    issue {
      id
      identifier
      title
      description
    }
  }
}
```

**Variables:**
```json
{
  "id": "issue-uuid",
  "input": {
    "title": "Updated title",
    "description": "Updated description"
  }
}
```

**Updatable Fields in IssueUpdateInput:**
- `title: String`
- `description: String`
- `assigneeId: String`
- `stateId: String`
- `priority: Int`
- `projectId: String`
- `cycleId: String`
- `labelIds: [String!]`
- `dueDate: TimelessDate` - ISO 8601 date string (YYYY-MM-DD)
- `estimate: Float`

### Archive Issue

```graphql
mutation ArchiveIssue($id: String!) {
  issueArchive(id: $id) {
    success
    lastSyncId
  }
}
```

**Variables:**
```json
{
  "id": "issue-uuid"
}
```

**Note:** Archiving is Linear's equivalent of "closing" an issue.

---

## Supporting Queries

### Get Teams

```graphql
query GetTeams {
  teams {
    nodes {
      id
      name
      key           # e.g., "ENG"
      description
    }
  }
}
```

**Usage:** Get available teams for issue creation and filtering.

### Get Team Workflow States

```graphql
query GetWorkflowStates($teamId: String!) {
  workflowStates(filter: { team: { id: { eq: $teamId } } }) {
    nodes {
      id
      name
      type          # "backlog", "unstarted", "started", "completed", "canceled"
      position
    }
  }
}
```

**Usage:** Get available states for status selector.

### Get Team Members

```graphql
query GetTeamMembers($teamId: String!) {
  team(id: $teamId) {
    members {
      nodes {
        id
        name
        email
        active
      }
    }
  }
}
```

**Usage:** Get assignable users for a team.

### Get Projects

```graphql
query GetProjects($teamId: String) {
  projects(filter: { team: { id: { eq: $teamId } } }) {
    nodes {
      id
      name
      description
      state
      lead {
        name
      }
    }
  }
}
```

### Get Labels

```graphql
query GetLabels($teamId: String) {
  issueLabels(filter: { team: { id: { eq: $teamId } } }) {
    nodes {
      id
      name
      color
    }
  }
}
```

### Get Issue Comments

```graphql
query GetIssueComments($issueId: String!) {
  issue(id: $issueId) {
    comments {
      nodes {
        id
        body
        user {
          id
          name
        }
        createdAt
        updatedAt
      }
    }
  }
}
```

### Create Comment

```graphql
mutation CreateComment($input: CommentCreateInput!) {
  commentCreate(input: $input) {
    success
    comment {
      id
      body
    }
  }
}
```

**Variables:**
```json
{
  "input": {
    "issueId": "issue-uuid",
    "body": "Comment text"
  }
}
```

---

## Priority Values

Linear uses integer priority values:
- `0` - No priority
- `1` - Urgent (🔴)
- `2` - High (🟠)
- `3` - Normal (🟡)
- `4` - Low (🟢)

---

## Implementation Notes

1. **Pagination:** Linear uses cursor-based pagination (Relay spec). Use `first`/`after` for forward pagination, `last`/`before` for backward.

2. **UUID vs Identifier:** Most API calls require UUIDs (the `id` field), not human-readable identifiers like "ENG-123". Store both when caching.

3. **Archived Issues:** By default, archived issues are excluded. Pass `includeArchived: true` in filters to show them.

4. **Rate Limiting:** Linear's API has rate limits. Handle 429 responses gracefully.

5. **Team Selection:** Issue creation requires a `teamId`. Query teams first and prompt user if multiple teams exist.

---

## References

- [Linear API Docs](https://linear.app/developers/graphql)
- [GraphQL Schema on GitHub](https://github.com/linear/linear/blob/master/packages/sdk/src/schema.graphql)
- [Apollo Studio Explorer](https://studio.apollographql.com/public/Linear-API/variant/current/home)

Sources:
- [Getting started – Linear Developers](https://linear.app/developers/graphql)
- [Linear API's Graph | GraphOS Studio](https://studio.apollographql.com/public/Linear-API/variant/current/schema/reference/objects/Mutation)
- [linear/packages/sdk/src/schema.graphql at master · linear/linear](https://github.com/linear/linear/blob/master/packages/sdk/src/schema.graphql)
