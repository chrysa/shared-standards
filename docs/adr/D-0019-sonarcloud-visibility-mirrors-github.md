# D-0019: A SonarCloud project has the same visibility as its GitHub repo

- **Status:** Accepted
- **Date:** 2026-11-08
- **Deciders:** chrysa
- **Pillars touched:** none
- **Supersedes / Superseded by:** — (complements D-0016, the `SonarCloud` required check)

## Context

Every repo on the canonical CI analyses its code on the `chrysa` SonarCloud
organization. SonarCloud creates a project with the organization's default
visibility, not the GitHub repo's. Nothing kept the two in line, and they drift
in both directions:

- **Public SonarCloud project, private repo.** SonarCloud shows the analysed
  source code to anyone. A public project leaks the code of a private repo.
- **Private SonarCloud project, public repo.** Nothing leaks, but the free plan
  caps the organization at 50,000 lines of code, and only private projects count
  toward it. A private project for a public repo spends quota for nothing. The
  cap is full, so new private repos can no longer be analysed.

The survey of 2026-11-08 found no public project for a private repo. It found
seven public repos with a private project: `cdn-explorer`, `django-app-forge`,
`django-pytest`, `django-query-optimizer`, `django-traceid`, `gestureOS` and
`lifeos`.

## Decision

A SonarCloud project always has the same visibility as its GitHub repo:
public repo, public project; private repo, private project.

- **New repo:** after the first analysis, set the project's visibility to the
  repo's.
- **Repo goes public:** set the project to public on the same day.
- **Repo goes private:** set the project to private **before** you change the
  repo, so the source is never public for a moment.
- **Repo renamed:** change the project key (*Project Settings > Update Key*).
  Do not create a new project. The history stays with the project.
- **Repo archived:** delete the project, or leave it with the repo's
  visibility.

## Fatal hypothesis

A public SonarCloud project shows an anonymous visitor nothing that the public
GitHub repo does not already give away: anyone can clone the code and run the
same analysis.

## Kill-test

At each fleet Sonar audit, and at the latest on 2026-12-08, open one public
project of a public repo in a private browser window. If the page shows an
anonymous visitor anything the repo does not expose (a secret value, CI
environment details, analysis of a branch that is not public), the hypothesis
is false. Then set the affected projects to private and supersede this ADR with
the exception. Not mechanised: it needs a human look at the rendered pages, and
the fleet scan has no valid organization admin token today.

## Validation gate

The rule counts as applied when a survey finds zero mismatches between the two
visibilities. With an organization admin token, the survey covers every
project. Without one, it covers public projects plus the projects that a CI
check-run references, and it says so. Only then does the check move into the
fleet scan.

## Options considered

| Option | Why not |
| ------ | ------- |
| Every project private | Public repos spend the 50,000-line quota, which is full. SonarCloud badges in public READMEs need a public project. |
| Every project public | Leaks the code of private repos. |
| Keep the organization default and fix projects one by one | That is the drift the 2026-11-08 survey found. |

## How to check

Without a token, SonarCloud lists only public projects:

```bash
# Public projects of the organization
curl -s 'https://sonarcloud.io/api/components/search_projects?organization=chrysa&ps=500' \
  | jq -r '.components[].key'

# 200 = public; 404 = private or missing
curl -s -o /dev/null -w '%{http_code}\n' \
  'https://sonarcloud.io/api/components/show?component=chrysa_<repo>'
```

A `404` does not tell private from missing. A `SonarCloud Code Analysis`
check-run on the repo's default branch proves the project exists, so
"check-run present" plus "`404` without a token" means private.

With an organization admin token, one call returns the visibility of every
project:

```bash
curl -s -H "Authorization: Bearer $SONAR_TOKEN" \
  'https://sonarcloud.io/api/projects/search?organization=chrysa&ps=500' \
  | jq -r '.components[] | "\(.key) \(.visibility)"'
```

Compare that list with `gh repo list chrysa --json name,visibility`.

## How to fix

In the SonarCloud UI, open the project and go to *Administration >
Permissions*, then pick *Public* or *Private*. Or use the Web API with an
organization admin token:

```bash
curl -s -X POST -H "Authorization: Bearer $SONAR_TOKEN" \
  'https://sonarcloud.io/api/projects/update_visibility' \
  -d project=chrysa_<repo> -d visibility=public
```

## Consequences

- No private code is shown on a public SonarCloud page.
- Public repos stop spending the 50,000-line quota. The seven projects of the
  2026-11-08 survey free room for the private repos that can no longer be
  analysed.
- Every Sonar audit compares the two visibilities. Without an admin token, the
  check cannot see a private project that no CI run references; the report must
  say so.
- Changing visibility needs organization admin rights. When the automation
  token is not valid, the change is a manual step for the owner.
