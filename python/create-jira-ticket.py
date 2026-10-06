#python3 <(curl -L https://raw.githubusercontent.com/fraserswaxway/helpers/refs/heads/main/python/create-jira-ticket.py) -h
# -n sentinel -o create -d /opt/oracle -p 11521 -c changeit
#

"""
Epic -> Story -> Sub-task

JIRA_PAT=NTQ2MDQxMzQ3NTkxOg5QPJc8RdjzoHIVTIvvvsMU9tvT JIRA_EMAIL=sfraser@axway.com python3 \
 create_jira_issue.py \
 --url https://jira.axway.com \
 --project "WFSP" \
 --epic "WFSP-147" \
 --parent "WFSP-135" \
 --issue-type Sub-task \
 --summary "SENT[Sub-task]: log when expected attribute values are missing" \
 --description "SENT[Sub-task]: log when expected attribute values are missing" \
 --assignee "sfraser@axway.com"
"""

import argparse
import json
import os
import sys

import requests


class Jira:
    def __init__(self, base_url: str):
        self.base = base_url.rstrip("/")
        self.s = requests.Session()
        self.s.headers.update({"Accept": "application/json", "Content-Type": "application/json"})

        if os.getenv("JIRA_PAT"):
            self.s.headers["Authorization"] = f"Bearer {os.environ['JIRA_PAT']}"
        elif os.getenv("JIRA_EMAIL") and os.getenv("JIRA_API_TOKEN"):
            self.s.auth = (os.environ["JIRA_EMAIL"], os.environ["JIRA_API_TOKEN"])
        elif os.getenv("JIRA_USER") and os.getenv("JIRA_PASSWORD"):
            self.s.auth = (os.environ["JIRA_USER"], os.environ["JIRA_PASSWORD"])
        else:
            sys.exit("No credentials: set JIRA_EMAIL + JIRA_API_TOKEN (Cloud) or JIRA_PAT (Server/DC).")

        self.cloud = None  # resolved by detect()

    # ---- HTTP helpers -------------------------------------------------------
    def _CallHTTP(self, method, path, **additionalArguments):
        print("----------------------------")
        print(method + " " + self.base + path)
        for key, value in additionalArguments.items():
            print(f"{key}: {value}")
        # if method == "POST": return
        r = self.s.request(method, f"{self.base}{path}", timeout=30, **additionalArguments)
        if not r.ok:
            try:
                detail = r.json()
            except ValueError:
                detail = r.text[:500]
            sys.exit(f"Jira {method} {path} failed: HTTP {r.status_code}\n{json.dumps(detail, indent=2)}")
        return r.json() if r.content else {}

    # ---- lookups ------------------------------------------------------------
    def detect(self, forced=None):
        if forced:
            self.cloud = forced == "cloud"
        else:
            info = self._CallHTTP("GET", "/rest/api/2/serverInfo")
            self.cloud = info.get("deploymentType", "").lower() == "cloud"
        self.api = "/rest/api/3" if self.cloud else "/rest/api/2"

    def get_parent(self, key):
        return self._CallHTTP("GET", f"{self.api}/issue/{key}", params={"fields": "issuetype,project,summary"})

    def epic_link_field(self):
        """Server/DC: id of the 'Epic Link' custom field (e.g. customfield_10014), or None."""
        for f in self._CallHTTP("GET", "/rest/api/2/field"):
            custom = (f.get("schema") or {}).get("custom", "")
            if f.get("name") == "Epic Link" or custom.endswith(":gh-epic-link"):
                return f["id"]
        return None

    def find_user(self, query):
        """Return an assignee object for the given email/username."""
        if self.cloud:
            users = self._CallHTTP("GET", "/rest/api/3/user/search", params={"query": query})
            if not users:
                sys.exit(f"No Jira user found for '{query}'")
            return {"accountId": users[0]["accountId"]}
        users = self._CallHTTP("GET", "/rest/api/2/user/search", params={"username": query})
        if not users:
            sys.exit(f"No Jira user found for '{query}'")
        return {"name": users[0]["name"]}

    def create_issue(self, fields):
        return self._CallHTTP("POST", f"{self.api}/issue", data=json.dumps({"fields": fields}))


def adf(text):
    """Plain text -> Atlassian Document Format (required by API v3 for description)."""
    paragraphs = [p for p in text.split("\n\n")] if text else []
    return {
        "type": "doc",
        "version": 1,
        "content": [
            {"type": "paragraph", "content": [{"type": "text", "text": p}]} for p in paragraphs if p.strip()
        ],
    }


def main():
    parser = argparse.ArgumentParser(description="Create Jira ticket [IMPORTANT: Epic has nothing, Story must have --epic, Sub-task must have --story]")
    parser.add_argument("--epic", required=False, help="Epic issue key for Story, e.g. INT-4982")
    parser.add_argument("--story", required=False, help="Story issue key for Sub-Task, e.g. INT-42")

    #parser.add_argument("--issue-type", required=True, help="Issue type name (Epic, Story, Sub-task)")
    parser.add_argument("--summary", required=True, help="Task title")
    parser.add_argument("--description", required=True, default="", help="Task description (plain text; blank line = new paragraph)")
    parser.add_argument("--project", required=True, help="Project key")
    parser.add_argument("--assignee", required=True, help="Assignee email")
    parser.add_argument("--labels", help="Comma-separated labels")
    parser.add_argument("--priority", help="Priority name, e.g. High")
    parser.add_argument("--url", required=True, default=os.getenv("JIRA_URL"), help="Jira base URL (or set JIRA_URL)")
    parser.add_argument("--dry-run", action="store_true", help="Print the payload without creating the issue")
    parser.add_argument(
        '--issue-type',
        required=True,
        choices=['Epic', 'Story', 'Sub-task'],
        help='Issue type'
    )

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--type-epic', help='Database connection string')
    group.add_argument('--type-story', help='Path to a configuration file')

    args = parser.parse_args()

    if not args.url:
        sys.exit("Set JIRA_URL or pass --url")

    jira = Jira(args.url)
#    jira.detect(args.deployment)

    # Epic has nothing
    # Story has an epic
    # Sub-task as parent

    if args.issue_type.lstrip().casefold().startswith("e".casefold()):
        args.issue_type = 'Epic'

#    if args.issue-type is None:
#        if args.issue-type..strip()
#    if args.story


    #"parent": {"key": args.story},

    parent = jira.get_parent(args.story)
    parent_type = parent["fields"]["issuetype"]["name"]
    #if parent_type.lower() != "epic":
    #    print(f"Warning: {args.story} is args '{parent_type}', not an Epic -- linking as parent anyway.", file=sys.stderr)
    print("===== args.project is [" + args.project + "] =====")
    print("===== parent[fields][project][key] is [" + parent["fields"]["project"]["key"] + "] =====")
    project = args.project or parent["fields"]["project"]["key"]
    print("===== project is [" + project + "] =====")

    fields = {
        "project": {"key": project},
        "issuetype": {"name": args.issue_type},
        "summary": args.summary,
    }
    if args.description:
        fields["description"] = adf(args.description) if jira.cloud else args.description
    if args.labels:
        fields["labels"] = [l.strip() for l in args.labels.split(",") if l.strip()]
    if args.priority:
        fields["priority"] = {"name": args.priority}
    if args.assignee:
        fields["assignee"] = jira.find_user(args.assignee)

    # --- link to the epic ---
    epic_field = jira.epic_link_field()
    if epic_field:
        fields[epic_field] = args.epic

    if args.dry_run:
        print(json.dumps({"fields": fields}, indent=2))
        return

    created = jira.create_issue(fields)
    key = created["key"]
    print(f"Created {key} in epic {args.story}: {jira.base}/browse/{key}")


if __name__ == "__main__":
    main()
