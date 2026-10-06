#python3 <(curl -L https://raw.githubusercontent.com/fraserswaxway/helpers/refs/heads/main/python/create-jira-ticket.py) -h

"""
Epic -> Story -> Sub-task

python3 create-jira-ticket.py \
 Epic \
 --url "https://jira.axway.com" \
 --email "sfraser@axway.com" \
 --token "NTQ2...MU9tvT" \
 --project "WFSP" \
 --component "Sentinel" \
 --summary "SENT[Epic]: something for sentinel over 2 weeks" \
 --name "SENT[Epic]: something for sentinel over 2 weeks" \
 --assignee "sfraser@axway.com" \
 --dry-run

python3 <(curl -L https://raw.githubusercontent.com/fraserswaxway/helpers/refs/heads/main/python/create-jira-ticket.py) \
 Epic \
 --url "https://jira.axway.com" \
 --email "sfraser@axway.com" \
 --token "NTQ2...MU9tvT" \
 --project "WFSP" \
 --component "Sentinel" \
 --summary "SENT[Epic]: something for sentinel over 2 weeks" \
 --name "SENT[Epic]: something for sentinel over 2 weeks" \
 --assignee "sfraser@axway.com" \
 --debug
"""

import argparse
import json
import sys
import requests


class Jira:
    def __init__(self, base_url: str, token: str, email: str, debug: bool = False):
        self.debug = debug
        self.token = token
        self.email = email
        self.base = base_url.rstrip("/")
        self.s = requests.Session()
        self.s.headers.update({"Accept": "application/json", "Content-Type": "application/json"})

        self.s.headers["Authorization"] = f"Bearer {self.token}"
        self.cloud = None  # resolved by detect()

    def _showInformation(self, method, path, **additionalArguments):
        print(method + " " + self.base + path)
        for key, value in self.s.headers.items():
            print(f"{key}: {value}")
        if 'params' in additionalArguments:
            print("params: " + json.dumps(additionalArguments['params'], indent=2))
        if 'data' in additionalArguments:
            if isinstance(additionalArguments['data'], str):
                dict = json.loads(additionalArguments['data'])
                print("data: " + json.dumps(dict, indent=2))
            else:
                print("data: " + json.dumps(additionalArguments['data'], indent=2))
            #if object use dumps .. if string otherwise

    # ---- HTTP helpers -------------------------------------------------------
    def _CallHTTP(self, method, path, **additionalArguments):
        if (self.debug):
            self._showInformation(method, path, **additionalArguments)
        #print(self.s.headers)
        #print(json.dumps(self.s.headers, indent=2))
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
    def detect(self):
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

    def component_field(self):
        for f in self._CallHTTP("GET", "/rest/api/2/field"):
            custom = (f.get("schema") or {}).get("custom", "")
            if "component".casefold() in f.get("name").casefold():
                return f["id"]
        return None

    def epic_name_field(self):
        for f in self._CallHTTP("GET", "/rest/api/2/field"):
            custom = (f.get("schema") or {}).get("custom", "")
            if "epic name".casefold() in f.get("name").casefold():
                return f["id"]
        return None

    # classification .. Custom Project
    def epic_classification_field(self):
        for f in self._CallHTTP("GET", "/rest/api/2/field"):
            custom = (f.get("schema") or {}).get("custom", "")
            if "epic classification".casefold() in f.get("name").casefold():
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

        #return self._CallHTTP("POST", f"{self.api}/issue", data=json.dumps({"fields": fields}))
        #data={"fields": fields}

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

    parent_parser = argparse.ArgumentParser(add_help=False)
    parent_parser.add_argument("--debug", required=False, action='store_true', help="provide information on commands being executed")
    parent_parser.add_argument("--url", required=True, help="jira site such as https://jira.axway.com")
    parent_parser.add_argument("--token", required=True, help="personal access token such as NTQ2...MU9tvT")
    parent_parser.add_argument("--email", required=True, help="email used by Jira such as someone@axway.com")
    parent_parser.add_argument("--project", required=True, help="project key such as WFSP")
    parent_parser.add_argument("--summary", required=True, help="summary")
    #parent_parser.add_argument("--description", required=True, help="description")
    parent_parser.add_argument("--assignee", required=True, help="assignee email")
    parent_parser.add_argument("--dry-run", required=False, action='store_true', help="show request information and exit")
    parent_parser.add_argument(
        '--component',
        required=True,
        choices=['Fusion','SmartEdge','ST','Sentinel'],
        help='Component'
    )


    type_parsers = parser.add_subparsers(dest='type', required=True)
    epic_parser = type_parsers.add_parser('Epic', help='Epic', parents=[parent_parser])
    story_parser = type_parsers.add_parser('Story', help='Story', parents=[parent_parser])
    task_parser = type_parsers.add_parser('Sub-task', help='Sub-task', parents=[parent_parser])

    epic_parser.add_argument("--name", required=True, help="Epic name")

    story_parser.add_argument(
        '--story-points',
        required=True,
        choices=[1, 2, 3, 5, 8, 13],
        help='Story points'
    )

    story_parser.add_argument("--epic", required=False, help="Epic issue key for Story, e.g. INT-4982")

    # epic name .. not description

    args = parser.parse_args()

    jira = Jira(args.url,args.token,args.email,args.debug)
    jira.detect()

#    jira.detect(args.deployment)

    # Epic has nothing
    # Story has an epic
    # Sub-task as parent

    # keep track of type for the rest api
    # keep track of epic or parent

    fields = {
        "project": {"key": args.project},
        "issuetype": {"name": args.type},
        "summary": args.summary,
        "assignee": jira.find_user(args.assignee),
        jira.component_field(): [{"name": args.component}],
    }
    # epic name and not description
    # "description": adf(args.description) if jira.cloud else args.description,

    # --- link to the epic ---
    epic_field = jira.epic_link_field()
    #if epic_field:
    #    fields[epic_field] = args.epic

# classification .. Custom Project
    if args.type == "Epic":
        fields[jira.epic_name_field()] = args.name
        fields[jira.epic_classification_field()] = {"value": "Custom Project"}

    if args.dry_run:
        jira._showInformation("POST",jira.api+"/issue",data=fields)
        # return self._CallHTTP("POST", f"{self.api}/issue", data=json.dumps({"fields": fields}))
        # print("POST " + args.url + jira.api)
        # print(json.dumps({"fields": fields}, indent=2))
        return

    created = jira.create_issue(fields)
    key = created["key"]
    print(f"Created {key} of type {args.type} see {jira.base}/browse/{key}")


if __name__ == "__main__":
    main()
