# Azure + AI-103 Reference Guide (Weeks 1-2)

Your own look-up guide. Each part has: **what it is**, **why it matters**, **worked example**, **commands**, **gotchas**, and **self-test**. Day-by-day lab notes are in `week1.md` and `week2.md`; the PDF is a short recap. This file is the long, explained version.

Jump to: [Part 0 Account & cost](#part-0--account-structure-and-cost) · [Part 1 Cloud concepts](#part-1--cloud-concepts) · [Part 2 Regions, Policy, groups, ARM, locks](#part-2--regions-policy-resource-groups-arm-locks) · [Part 3 Bicep](#part-3--bicep) · [Part 4 Pricing](#part-4--pricing) · [Part 5 Compute](#part-5--compute) · [Part 6 Networking](#part-6--networking) · [Part 7 Storage](#part-7--storage) · [Part 8 Storage security](#part-8--storage-security-sas-and-lifecycle) · [Part 9 Identity & RBAC](#part-9--identity-and-rbac) · [Part 10 Key Vault](#part-10--key-vault-and-managed-identity) · [Cheat sheets](#cheat-sheets)

---

## Part 0 - Account structure and cost

```
Billing account  (who pays)
 └── Subscription  (a billing + access boundary; "Study Subscription")
      └── Resource group  (a folder for related resources)
           └── Resource  (a VM, a storage account, a vault ...)
```

- **Billing account scope** covers the whole account; **subscription scope** covers one subscription. A budget at billing-account scope (ours: `budget-monthly-study`, $2/month) watches everything.
- **A budget only sends emails. It does not stop spending.** Pay-as-you-go with spending limit off means anything above the free amounts is charged to your card.
- **Rule for every lab:** deploy, check, **delete the resource group**, then verify `0 groups, 0 resources`. Key Vault needs an extra **purge** (see Part 10).
- Keep the CLI on the right subscription: `az account show --query name -o tsv` should say **Study Subscription**.

**Self-test:** What stops spending if a lab is forgotten? *(Nothing automatic; only deleting the resources. A budget just warns.)*

---

## Part 1 - Cloud concepts

### What is the cloud?
Renting computing (servers, storage, networks) over the internet and paying for what you use, instead of buying and running your own hardware.

| Model | Meaning | Example |
|---|---|---|
| Public | Shared provider hardware | Azure |
| Private | Hardware used by one organisation | A company's own datacenter |
| Hybrid | A mix of own servers and cloud | A bank keeps records on-premises and runs its website in Azure |

### Shared responsibility
Microsoft **always** secures the physical datacenter. **You always** secure your data, identities and access. The middle changes with the service type:

| Type | You rent | You manage | Example |
|---|---|---|---|
| **IaaS** | machines, storage, networks | OS, patches, apps, data | Virtual Machine |
| **PaaS** | a platform for your code | your app and data | App Service, Functions |
| **SaaS** | a finished app | your data and users | Microsoft 365 |

**Example:** the OS of a VM is patched by **you**; the OS under App Service is patched by **Microsoft**.

### Benefits (know these words)
- **High availability** - the service stays up when parts fail.
- **Scalability** - you *can* add capacity: scale **up** (bigger server) or **out** (more servers).
- **Elasticity** - capacity grows and shrinks **automatically** with demand (more servers on a sale day, fewer afterwards).
- **Reliability** - it recovers from failures. **Predictability** - performance and cost are consistent.
- **Security and governance** - protection of data; rules (Policy) keep things compliant.

### Consumption pricing
Pay only for what you use. An idle Function app costs almost nothing (but it needs a storage account, which has a small cost).

**Self-test:** Servers added automatically for a sale and removed after - scalability or elasticity? *(Elasticity.)*

---

## Part 2 - Regions, Policy, resource groups, ARM, locks

### Regions, zones, pairs
| Term | Meaning | Protects against |
|---|---|---|
| Region | Geographic area with datacenters (Central India) | - |
| Availability zone | Separate datacenter inside one region | One datacenter failing |
| Region pair | Two regions in one geography that back each other up (Central India and South India) | A whole region failing |

**Why not always the cheapest region?** Some lack zones or a good pair; also consider latency, which services/AI models exist there, compliance and price.

### Azure Policy
A rule Azure checks every time a resource is created or changed. Parts: **definition**, **assignment** (where it applies = scope), **parameters**, **effect** (Deny, Audit, Modify, DeployIfNotExists).

- **Policy vs RBAC:** RBAC = *who* may do something. Policy = *what* is allowed to exist. Even an Owner is blocked by a Deny policy.
- **Our lab:** "Require a tag and its value" (`project=learning`). Creating a storage account without the tag failed with `RequestDisallowedByPolicy` - in the portal, CLI and Bicep alike.

### Resource groups and ARM
- A **resource group** is a folder. **Deleting it deletes everything inside.** Deleting the group is how we clean every lab.
- **ARM (Azure Resource Manager)** is the single front door behind the portal, CLI, Bicep and SDKs. Policy, RBAC and locks are enforced there, so no tool can skip them.
- **Tags** (`project`, `phase`, `owner`) help with cost tracking, ownership, environment and cleanup. **Tags are not inherited** by resources in the group - set them on each resource. Never put secrets in tags.

### Locks
| Lock | Effect |
|---|---|
| Delete (CanNotDelete) | Blocks deletion |
| Read-only | Blocks changes |

Deleting a locked group fails with "has locks applied" until you remove the lock.

**Self-test:** Why did Policy block the storage account in the portal, CLI *and* Bicep? *(All go through ARM.)*

---

## Part 3 - Bicep

Bicep describes the **end state** of Azure resources in a short text file. It compiles to an ARM template.

- **Idempotent:** deploy the same file twice and nothing changes (what-if shows `NoChange`).
- **Always preview first:** `az deployment sub what-if ...`
- **Scopes:** a resource group is created at **subscription scope** (`targetScope = 'subscription'`); things inside it are **modules** scoped to the group.
- **Names:** global names (storage, Key Vault) use `uniqueString(rg.id)` so they're unique but repeatable.
- **In companies:** the portal is for exploring, the CLI for scripts, and infrastructure-as-code (Bicep, or Terraform for multi-cloud) run by a pipeline for real environments.

```bash
cd infra
az deployment sub what-if --location centralindia --template-file lab4-storage-security.bicep
az deployment sub create  --location centralindia --template-file lab4-storage-security.bicep
az group delete --name rg-learning-lab4 --yes --no-wait
```

Our files: `lab1.bicep` (group + tags + lock), `lab2-network.bicep`, `lab3-storage.bicep`, `lab4-storage-security.bicep`, `lab5-identity.bicep`, `lab6-keyvault.bicep`, and modules in `infra/modules/`.

**Self-test:** What does what-if do? *(Previews the changes without making them.)*

---

## Part 4 - Pricing

- **Pricing Calculator** estimates a design before you build it. It is an **estimate, not a bill**. **TCO Calculator** compares on-premises vs Azure.
- App Service Basic B1, Central India, 730 hours: **Windows $60.59/month vs Linux $13.14/month** (the Windows price includes the licence). Choose Linux unless the app needs Windows.
- Functions Consumption: first **1M executions** and **400,000 GB-s** a month are free; $0 when idle.
- Storage: writes and list/create-container operations cost more than reads; data retrieval is $0 in Hot; data write is free.

---

## Part 5 - Compute

| Option | Billing | Best for | Example |
|---|---|---|---|
| Virtual Machine (IaaS) | per hour **while it exists** | full OS control, legacy apps | an old app with a custom installer |
| Containers (Container Apps / ACI / AKS) | per second of vCPU + memory | portable apps, microservices | a packaged API |
| App Service (PaaS) | per hour for the plan | web apps/APIs with steady traffic | a website used all day |
| Functions (serverless) | per execution and run time; $0 idle | small event-driven jobs | process a file when uploaded |

**Worked example (quiz Q1):** a job runs 40 times a day for 2 seconds each. That is 80 seconds of work a day. A **VM** is billed for all 86,400 seconds a day, even when idle. **Functions** bills only for the 80 seconds (and the free grant likely covers it) -> **Functions**.

**Gotcha:** shutting a VM down from *inside* the OS keeps compute billing. Use **stop and deallocate** (portal/CLI). The disk (and any static IP) still bills.

**Decision shortcut:** steady all-day traffic -> App Service. Occasional event-driven work -> Functions. Need full OS control -> VM. Packaged/portable -> containers.

---

## Part 6 - Networking

- **VNet** - your private network in Azure (free). **Subnet** - a section of it. **NSG** - allow/deny rules for traffic on a subnet or NIC. **DNS** - turns names into IPs; controls no access. **Public IP** - internet-reachable address (small hourly cost). **Private endpoint** - gives a service a private address inside your VNet.
- **Inbound** = traffic coming **in** to a resource; **outbound** = traffic going **out**. One connection is outbound for the sender and inbound for the receiver. NSGs are **stateful**: replies need no extra rule.
- **AWS equivalent:** VPC (security group + network ACL ~ NSG; VPC endpoint/PrivateLink ~ private endpoint).
- **Use a VNet** for VMs, private/internal resources, VPN/ExpressRoute links, private endpoints, and traffic filtering. Simple public PaaS (Static Web Apps, basic Functions) doesn't need one while learning. Test: "would a public address be a problem?"

### How NSG rules are evaluated
Rules are checked from the **lowest priority number upward**. The **first match wins** and processing stops. Azure adds default rules at the end (e.g. `AllowVnetInBound` at 65000, `DenyAllInBound` at 65500).

**Our lab:** `vnet-learning` 10.0.0.0/16 with `snet-web` (10.0.1.0/24, allows 443 from the Internet) and `snet-db` (10.0.2.0/24). `nsg-db` has:

| Priority | Name | Allow/Deny | Source | Port |
|---|---|---|---|---|
| 100 | allow-sql-from-web-subnet | Allow | 10.0.1.0/24 | 1433 |
| 4000 | deny-all-other-inbound | Deny | * | * |
| 65000 | AllowVnetInBound (default) | Allow | VirtualNetwork | * |

**Worked example (quiz Q2):** who can reach the database on port 1433?

| Request from | Rule 100 (from 10.0.1.0/24)? | Rule 4000 (deny all)? | Result |
|---|---|---|---|
| **10.0.1.7** (web subnet) | **Matches** -> Allow, stop | not reached | **Allowed** |
| **10.0.3.5** (another subnet in the same VNet) | No (not in 10.0.1.0/24) | **Matches** -> Deny, stop | **Denied** by rule 4000 |
| **The internet** | No | **Matches** -> Deny | **Denied** |

**Why the explicit deny matters:** without rule 4000, the 10.0.3.5 request would fall through to the default `AllowVnetInBound` (65000), because 10.0.3.5 is inside the same VNet. **A VNet is not a wall** - subnets in one VNet can reach each other unless an NSG denies it.

**Self-test:** Two rules: priority 100 allow, priority 200 deny, same traffic. Which applies? *(100; the first match wins.)*

---

## Part 7 - Storage

A **storage account** holds four services: **Blob** (files/objects; what DocuMind uses), **Files** (shares), **Queue** (messages), **Table** (key-value).

### Redundancy (how many copies, where)
| Option | Copies | Protects against |
|---|---|---|
| LRS | 3 in one datacenter | a disk/rack failing |
| ZRS | 3 across availability zones | a datacenter failing |
| GRS | LRS + a copy in the **paired region** | a whole region failing |
| GZRS | ZRS + paired-region copy | zone **and** region failure |

The secondary copy of GRS/GZRS is not readable unless you choose **RA-GRS / RA-GZRS**. The portal may default to GRS, so check it.

### Access tiers (cost vs access speed)
| Tier | Minimum stay | Storage cost | Read cost / speed |
|---|---|---|---|
| Hot | none | highest | cheapest, instant |
| Cool | 30 days | lower | higher, instant |
| Cold | 90 days | lower still | higher, instant |
| **Archive** | **180 days** | **lowest** | **offline: hours to rehydrate** before you can read; early-deletion fee if removed sooner |

**Worked example (quiz Q3):** contracts kept 7 years, almost never read, must survive a region failure.
- **Tier = Archive.** Rarely read, so we want the cheapest storage and accept slow retrieval. 7 years is far past the 180-day minimum, so no early-deletion fee.
- **Redundancy = GRS.** It keeps a copy in the paired region (Central India <-> South India), so one region failing doesn't lose the contracts.
- **Why GRS and not GZRS:** Archive tier is **not available on ZRS/GZRS/RA-GZRS** accounts (check the current Microsoft docs), so GRS is the practical combination here.
- **Trade-off:** if someone suddenly needs a contract, they wait hours for rehydration.

### Control plane vs data plane (a recurring trap)
- **Control plane** = managing the account (create, delete, change settings). Owner/Contributor roles cover this.
- **Data plane** = reading/writing the blobs themselves. Needs a **data role**: **Storage Blob Data Reader** (read) or **Storage Blob Data Contributor** (read + write + delete).

**Worked example (quiz Q4):** you are Owner and `az storage blob upload --auth-mode login` fails. Owner has no data actions. Uploading is a **write**, so the fix is **Storage Blob Data Contributor** (on the account or container - the narrowest scope that works). *Reader-type access would allow reads only, not an upload.*

Role changes take about a minute to apply (retry).

### Secure defaults we used
`allowBlobPublicAccess = false`, `minimumTlsVersion = TLS1_2`, `supportsHttpsTrafficOnly = true`, a private container. An anonymous request returns **409 `PublicAccessNotPermitted`**. Keyless access: `--auth-mode login` uses your Entra sign-in, with no account keys.

```bash
az storage blob upload --account-name <acc> --container-name documents --name hello.txt --file hello.txt --auth-mode login
az storage blob list   --account-name <acc> --container-name documents --auth-mode login -o table
```

### Bicep vs portal (what we noticed)
Core settings matched. The portal also turned on 7-day soft delete by default and may default to GRS; Bicep sets only what you write. Tags are never inherited from the group.

---

## Part 8 - Storage security (SAS and lifecycle)

### SAS (Shared Access Signature)
A **URL with a signature** that grants **limited access** (permissions, one blob or container, an expiry) without sharing the account key. **Treat the full URL like a password until it expires.**

| Type | Signed with | How to revoke |
|---|---|---|
| Account SAS | account key | only by **rotating the key** (breaks everything using it) |
| Service SAS | account key | rotate the key (or delete its stored access policy) |
| **User delegation SAS** (recommended) | **Entra credentials** | remove the signer's data role, or `revoke-delegation-keys` |

URL fields: `sp` permissions (`r`,`w`...), `se` expiry, `st` start, `sr` scope (`b` = one blob), `skoid` the signing identity, `sig` the signature (the only secret part).

**What we proved (CLI and portal):**
| Request | Result |
|---|---|
| No token | 409 PublicAccessNotPermitted |
| SAS read (`sp=r`) | 200 |
| Same SAS, try to write | 403 |
| Same SAS, a different blob | 403 |
| After `revoke-delegation-keys` | `AuthenticationFailed` (even though the link wasn't expired) |

**Backend pattern (a mobile app uploading a profile photo):**
1. The app asks the backend: "I want to upload".
2. The backend (using its **managed identity**) returns a **write-only SAS for one blob name, valid ~15 minutes**.
3. The app uploads straight to storage; the file never goes through your server.

The backend fetches a **user delegation key** occasionally (valid up to 7 days; cache it) and **signs each SAS locally** - no Azure call per link. It needs **Storage Blob Delegator** (to get the key) plus a data role (a SAS can't give more than its signer has). Generate a SAS only when the user needs a file, not on every API call.

**Gotchas:** an expiry already in the past gives a confusing `InvalidXmlNodeValue` error; use minutes/hours, never days. **User-bound SAS** (portal option) makes a link work only for one named, signed-in Entra user.

### Lifecycle management rule
Automatic housekeeping on the account (one policy, many rules). Ours (`infra/modules/lifecycle.bicep`): blobs under `documents/` move to **Cool after 30 days, Archive after 90, delete after 365**, counted from **last modification** (or last access, if access tracking is on). Rules run **about once a day**, so you can't watch them fire in one session.

Portal path: Storage account -> **Data management -> Lifecycle management -> Add a rule** (check with **Code view**).

**Self-test:** A SAS signed with the account key leaks. What is your only option? *(Rotate the account key.)*

---

## Part 9 - Identity and RBAC

- **Entra ID** = the directory of identities. It answers **"who are you?"** (authentication).
- **RBAC** answers **"what can you do?"** (authorization). A role assignment = **WHO + WHAT role + WHERE (scope)**.
- **Scopes inherit downward:** management group -> subscription -> resource group -> resource.

### Identities
| Identity | What it is |
|---|---|
| User | a person |
| Group | a set of users (assign roles to groups) |
| Service principal | an identity for an app, with a secret/certificate **you** must store and rotate |
| **Managed identity** | an identity for an Azure resource; **Azure creates and rotates the credential** (system-assigned = tied to one resource; user-assigned = a separate reusable resource) |

A managed identity has a **principalId** (object id; roles attach to this) and a **clientId** (appId; used to sign in).

### Main roles
| Role | Can do | Cannot do |
|---|---|---|
| **Owner** | everything, including assigning roles | - |
| **Contributor** | create, change and delete resources (even the resource group) | assign roles |
| **Reader** | view everything in scope | create, change or delete |

Plus **data roles** (Storage Blob Data ..., Key Vault Secrets ...). Memory trick - read the verb: **see = Reader, change = Contributor, give access = Owner.**

**Best practice:** assign roles to **groups**, at the **smallest scope** that works (least privilege).

### What we tested (test user in a group)
| Role on the resource group | Result |
|---|---|
| Reader | saw only that group, could read IAM; creating a storage account -> `AuthorizationFailed` on `deployments/validate/action`; deleting the group -> not authorized |
| + Contributor | created a storage account; **Add role assignment greyed out** |

### Reading a permission error
> The client **X** does not have authorization to perform action **Y** over scope **Z**.

That is **who, what, where** - the three parts of a missing role assignment.

### Managed identity vs account key
| | Account key in settings | Managed identity + role |
|---|---|---|
| Secret to store | yes | none |
| Person leaves | may have seen the key -> rotate it everywhere | disable the person's account; the app's identity is separate |
| If leaked | full control of the account | only the one role on one scope |
| Audit | "the key" | which identity did what |

**Example (quiz question):** a developer must *see* everything in `rg-docs-prod` but change nothing -> **Reader** on the resource group, via a group. Another must deploy but not grant access -> **Contributor** on that group.

---

## Part 10 - Key Vault and managed identity

**Key Vault** is one protected place for **secrets** (any string: API key, connection string), **keys** (cryptographic keys that never leave the vault) and **certificates** (TLS with renewal). Access is RBAC-controlled and logged; rotate in one place instead of in every app.

- **Permission model:** use **Azure RBAC** (`enableRbacAuthorization: true`) instead of old access policies.
- **Roles:** **Key Vault Secrets Officer** (manage secrets), **Key Vault Secrets User** (read secrets only).
- **Owner is control plane only.** An Owner got `ForbiddenByRbac` writing a secret until given Secrets Officer at the **vault** scope. Same split as storage.

### The flow with no password
```
App (has a managed identity) -> asks Entra for a token -> Entra ID
App -> "give me secret X" + token -> Key Vault -> checks RBAC (Secrets User?) -> returns the value
```

### What we tested (lab 6)
| Step | Result |
|---|---|
| Owner writes a secret, no data role | `ForbiddenByRbac` |
| Give yourself Secrets Officer, write secret | works (after ~1 minute) |
| Identity `id-learning-app` + Secrets User; container runs `az login --identity --client-id <clientId>` then `az keyvault secret show` | read the secret, no password in the command |
| Remove that one role assignment, run again | `ForbiddenByRbac`, empty value |

### Soft delete and purge
- Soft delete is on by default (7-90 days). A deleted vault can be recovered, and its **name stays reserved** for that time.
- **Purge protection** blocks permanent deletion until retention ends and **can never be turned off**. We left it off in labs (use it in production).
- Lab cleanup: delete the group, then `az keyvault purge --name <vault> --location centralindia` (portal: Key vaults -> **Manage deleted vaults** -> Purge).

**Gotchas:** newer Azure CLI needs `--client-id` (not `--username`) for `az login --identity`; role changes take a minute or more; an app must **check for errors** - my test `echo` exited 0 even though the read failed; `Microsoft.ContainerInstance` must be registered once per subscription.

**Self-test:** An app uses its managed identity with Secrets User. Which two things make the read succeed with no password in the code? *(1. The app runs with a managed identity. 2. That identity has a role like Key Vault Secrets User on the vault.)*

---

## Cheat sheets

### Which service?
| Need | Choose |
|---|---|
| Occasional, event-driven code | Functions |
| Website/API with steady traffic | App Service |
| Full OS control / legacy | VM |
| Store files | Blob storage |
| Hide a secret from code | Key Vault |
| App to reach Azure with no password | Managed identity + a role |
| Give a customer temporary file access | User delegation SAS |
| Cheapest long-term storage, rarely read | Archive tier (GRS if a region failure matters) |
| Block traffic between subnets | NSG deny rule |
| Prevent a type of resource | Azure Policy |
| Prevent deletion | Delete lock |

### Roles to remember
Owner · Contributor · Reader · Storage Blob Data Reader / Contributor · Storage Blob Delegator · Key Vault Secrets Officer / User.

### Error decoder
| Message | Means |
|---|---|
| `RequestDisallowedByPolicy` | a Policy (e.g. required tag) blocked it |
| `AuthorizationFailed` ... action ... scope | missing control-plane role (read who/what/where) |
| `ForbiddenByRbac` | missing **data-plane** role (Key Vault / storage data) |
| `PublicAccessNotPermitted` (409) | anonymous access is off; you need a token or identity |
| `AuthenticationFailed` / signature did not match | SAS signed by a key that was revoked or rotated |
| `InvalidXmlNodeValue` on Expiry | SAS expiry already in the past |
| "has locks applied" | a lock blocks the delete/change |

### Commands used so far
```bash
az account show --query name -o tsv                    # which subscription
az group list -o table                                 # what exists
az resource list --query 'length(@)' -o tsv            # count of resources
az deployment sub what-if / create --location centralindia --template-file X.bicep
az group delete --name <rg> --yes --no-wait
az role assignment list --scope <id> -o table
az role assignment create --assignee-object-id <id> --role "<role>" --scope <id>
az storage blob generate-sas ... --as-user --auth-mode login --permissions r --expiry <UTC time>
az storage account revoke-delegation-keys --name <acc> -g <rg>
az keyvault secret set --vault-name <v> --name <n> --value <x>
az keyvault list-deleted; az keyvault purge --name <v> --location centralindia
```
