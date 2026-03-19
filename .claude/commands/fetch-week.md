Fetch a Come Follow Me lesson page and generate a structured study markdown file.

The user will provide a URL like:
  https://www.churchofjesuschrist.org/study/manual/come-follow-me-for-home-and-church-old-testament-2026/12?lang=eng

Follow these steps:

## Step 1 — Fetch and extract content

Run these shell commands to extract the page content:

```bash
URL="<the URL the user provided>"

# Extract the page title
TITLE=$(curl -s "$URL" | htmlq --text 'title')

# Extract the full article body text
BODY=$(curl -s "$URL" | htmlq --text 'article p, article h1, article h2, article h3, article li')
```

## Step 2 — Derive the output path

From the URL path segment (e.g. `.../2026/12?lang=eng`):
- Extract the year (e.g. `2026`) and week number (e.g. `12`)
- Output file: `<year>/week_<number>.sc.md` (e.g. `2026/week_12.sc.md`)

From the page title (e.g. `March 16–22. "God Meant It unto Good": Genesis 42–50`):
- Extract the start date (e.g. `March 16, 2026`) and end date (e.g. `March 22, 2026`)
- Extract the start reference (e.g. `Genesis 42`) and end reference (e.g. `Genesis 50`). If only one chapter is assigned, use the same value for both.

## Step 3 — Generate the markdown file

Create the file at the path determined above. Structure it like this:

```markdown
---
startDate: <Month Day, Year>
endDate: <Month Day, Year>
refStart: <Book Chapter>
refEnd: <Book Chapter>
source: <URL>
---

# <Full lesson title from the page>

## Overview

<The introductory paragraphs of the lesson — the narrative/devotional intro before the study sections>

---

## Ideas for Personal Study

<Each study section as a level-3 heading (###) using the scripture reference as the heading.
Under each heading, include the section title (bolded) and the full body text of that section.>

---

## Ideas for Teaching Children

<Same treatment — each section as ###, scripture ref as heading, bold section title, full body text>

---

## My Notes

<!-- Space for personal study notes -->

```

## Step 4 — Confirm

Tell the user the file was written and show them the path. Offer to also open it or summarize the week's themes.
