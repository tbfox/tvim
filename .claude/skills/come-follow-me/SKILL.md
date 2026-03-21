---
name: come-follow-me
description: Fetch this week's Come Follow Me lesson and generate a structured study markdown file in local-plugins/scriptures.nvim/res/study/. Automatically determines the current week.
---

Fetch this week's Come Follow Me lesson and generate a structured study markdown file.

## Step 1 — Determine the current week's URL

Use today's date (available in your context as `currentDate`) to compute the ISO week number, then construct the URL:

```bash
# Get the current year and zero-padded ISO week number
YEAR=$(date +%Y)
WEEK=$(date +%V)

URL="https://www.churchofjesuschrist.org/study/manual/come-follow-me-for-home-and-church-old-testament-${YEAR}/${WEEK}?lang=eng"
```

## Step 1b — Check if file already exists

Before fetching anything, check if the output file already exists:

```bash
test -f "local-plugins/scriptures.nvim/res/study/${YEAR}/week_${WEEK#0}.sc.md"
```

If it does, tell the user something like: "Week $WEEK is already generated at `local-plugins/scriptures.nvim/res/study/$YEAR/week_$WEEK.sc.md`." and stop — do not proceed further.

## Step 2 — Fetch and extract content

```bash
# Extract the page title
TITLE=$(curl -s "$URL" | htmlq --text 'title')

# Extract the full article body text
BODY=$(curl -s "$URL" | htmlq --text 'article p, article h1, article h2, article h3, article li')
```

If the fetch fails or returns empty content, tell the user and stop.

## Step 3 — Derive the output path

From the URL (year and week number already known):
- Output file: `local-plugins/scriptures.nvim/res/study/<year>/week_<number>.sc.md` (e.g. `local-plugins/scriptures.nvim/res/study/2026/week_12.sc.md`)
- Use the numeric week number without leading zero for the filename (e.g. `12`, not `12`)

From the page title (e.g. `March 16–22. "God Meant It unto Good": Genesis 42–50`):
- Extract the start date (e.g. `March 16, 2026`) and end date (e.g. `March 22, 2026`)
- Extract the start reference (e.g. `Genesis 42`) and end reference (e.g. `Genesis 50`). If only one chapter is assigned, use the same value for both.

## Step 4 — Generate the markdown file

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

## Step 5 — Confirm

Tell the user the file was written and show them the path. Offer to also open it or summarize the week's themes.
