# Week 2 - Compute, networking, storage, identity

## Daily plan (learn + practical; cost flag in brackets)
- [x] Day 1: Compute options (VM, containers, App Service, Functions). Practical: compare the four in the Pricing Calculator. [free]
- [x] Day 2: Networking basics (VNet, subnets, NSG, DNS). Practical: create a VNet + subnet + NSG with Bicep. [free]
- [x] Day 3: Storage (blob, files, queue, table; redundancy; tiers). Practical: storage account, container, upload a file. [tiny cost; delete after]
- [x] Day 4: Storage security (SAS, lifecycle rules). Practical: SAS token + lifecycle rule. [tiny cost; delete after]
- [x] Day 5: Identity (Entra ID, RBAC, managed identity). Practical: test user/group, assign Reader at resource-group scope. [free]
- [ ] Day 6: Key Vault + managed identity. Practical: store a secret, read it with managed identity. [tiny cost; delete after]
- [ ] Day 7: Review + quiz. Practical: redo the week as Bicep, deploy, delete. [delete everything]

## Learned
### Day 1 - Compute
- **VM (IaaS):** full control of the OS; billed per hour while it exists. Use for legacy apps or custom installers.
- **Containers (Container Apps/ACI/AKS):** portable apps; billed per second of vCPU/memory.
- **App Service (PaaS):** web apps/APIs that run continuously; billed per hour for the plan (Linux B1 = $13.14/month, Windows B1 = $60.59/month).
- **Functions (serverless):** small event-driven code; billed per execution and run time; first 1M executions and 400,000 GB-s per month free; $0 when idle.
- **Steady traffic all day -> App Service** (predictable, always warm). **Occasional event-driven jobs -> Functions.**
- **Gotcha:** stopping a VM from inside the OS keeps billing compute. Use **stop and deallocate** (portal/CLI) to stop compute charges; you still pay for the disk.

### Day 2 - Networking
- **VNet:** our private network in Azure (free). Resources inside can talk privately. **Subnet:** a section of it. **NSG:** allow/deny rules for traffic on a subnet (or NIC). **DNS:** turns names into IPs, controls no access. **Public IP:** internet-reachable address (small hourly cost).
- **NSG rules** are checked from the lowest priority number upward; the first match wins. Azure adds default rules at 65000+ (e.g. `AllowVnetInBound`), so a VNet is *not* a wall: subnets in the same VNet can reach each other unless an NSG denies it.
- **Lab design:** `vnet-learning` 10.0.0.0/16 with `snet-web` (nsg-web allows 443 from Internet) and `snet-db` (nsg-db allows 1433 only from 10.0.1.0/24, then denies all other inbound at 4000). Files: `infra/lab2-network.bicep`, `infra/modules/network.bicep`. Deployed, inspected in the portal (Resource visualizer), then deleted.
- **When to use a VNet:** VMs, private/internal resources, connecting to our own network (VPN/ExpressRoute), private endpoints, filtering traffic, separating environments. Not needed for simple public PaaS (Static Web Apps, Functions, App Service) while learning. Test: "would a public address be a problem?"
- **AWS equivalent:** VPC (security group + network ACL ~ NSG; VPC endpoint/PrivateLink ~ private endpoint).
- **Private endpoint:** gives a service (e.g. AI Search) a private address inside our VNet so it needs no public one.

### Day 3 - Storage
- **Storage account services:** Blob (files; what DocuMind uses), Files (shares), Queue (messages), Table (key-value).
- **Redundancy:** LRS (3 copies, one datacenter), ZRS (3 zones), GRS (+ paired region), GZRS (zones + paired region). Pick GRS/GZRS to survive a region failure; the secondary copy isn't readable unless RA-GRS. The portal may default to GRS, so check it.
- **Tiers:** Hot (cheapest reads), Cool (30 days min), Cold (90), Archive (180 min, offline, hours to rehydrate, early-deletion fee). Old contracts nobody reads -> Archive.
- **Billing items:** writes and list/create-container ops cost more than reads; data retrieval is $0 in Hot; data write is free.
- **Control plane vs data plane:** Owner can manage the account but cannot read/write blobs until given a data role (Storage Blob Data Contributor). Role assignments take ~20-60 seconds to apply.
- **Keyless:** uploaded/read with `--auth-mode login` (our Entra sign-in), no account keys.
- **Secure defaults:** `allowBlobPublicAccess=false`, TLS 1.2, HTTPS only, private container. An anonymous request returned `PublicAccessNotPermitted` (HTTP 409).
- **Lab:** `infra/lab3-storage.bicep` + `infra/modules/storage.bicep` (name from `uniqueString`). Deployed, uploaded `hello.txt`, read it back, then deleted everything (verified 0 groups/0 resources).
- **Auto-created group:** `NetworkWatcherRG` (free) appears when a VNet is created in a region; it was deleted and will return when needed.

### Day 4 - Storage security (SAS + lifecycle)
- **SAS** = a URL with a signature giving limited access (permissions, one blob or container, expiry) without sharing the account key. Treat the full URL like a password until it expires.
- **Types:** account SAS and service SAS are signed with the account key; **user delegation SAS** is signed with Entra credentials (recommended). Fields in the URL: `sp` permissions, `se` expiry, `sr` scope (b = blob), `skoid` signing identity, `sig` signature.
- **Mobile-app pattern:** the backend issues the SAS with its managed identity, write-only, for one blob name, 15 minutes.
- **Revoking:** user delegation SAS -> remove the signer's data role or `az storage account revoke-delegation-keys` (kills all of them at once). Account/service SAS -> only rotate the account key (breaks everything using it). Always prefer short expiries.
- **Tested (CLI + portal):** no token -> 409 `PublicAccessNotPermitted`; SAS read -> 200; SAS write -> 403 (read-only); other blob -> 403; after revoke -> `AuthenticationFailed` while the link was still unexpired.
- **Gotcha:** the portal fills the start time when the panel opens; an expiry already in the past gives a confusing `InvalidXmlNodeValue` error. Portal "Authentication method: Access key" vs "Entra user account": switch to Entra for keyless.
- **User-bound SAS** (portal option): the link only works for one named, signed-in Entra user.
- **Lifecycle rule** (`infra/modules/lifecycle.bicep`, `managementPolicies/default`): under `documents/`, Cool after 30 days, Archive after 90, delete after 365 days since modification. Runs about once a day, so it can't be seen working in one session.
- **Lab:** `infra/lab4-storage-security.bicep`. Deployed, tested, group deleted.

### Day 5 - Identity (Entra ID, RBAC, managed identity)
- **Entra ID** = directory of identities (who are you?). **RBAC** = what can you do. A role assignment = WHO (user/group/identity) + WHAT (role) + WHERE (scope). Scopes inherit downward: management group > subscription > resource group > resource.
- **Identities:** user, group, service principal (app with a secret/certificate you must rotate), **managed identity** (Azure creates and rotates the credential; system-assigned = tied to one resource, user-assigned = reusable).
- **Roles:** Owner (all + assign roles), **Contributor** (all except assigning roles, but CAN delete the resource group), Reader (view only), plus data roles (Storage Blob Data ...). In the portal Owner/Contributor are under "Privileged administrator roles".
- **Best practice:** assign roles to groups, at the smallest scope that works (least privilege). Read the verb: see = Reader, change = Contributor, give access = Owner.
- **Tested:** test user in group `lab5-readers`. Reader: saw only `rg-learning-lab5`, could read IAM, create storage account -> `AuthorizationFailed` (deployments/validate/action), delete group -> not authorized. Contributor: created a storage account, but IAM "Add role assignment" was greyed out.
- **Error message recipe:** "client X does not have authorization to perform action Y over scope Z" = who, what, where of the missing role.
- **Managed identity vs account key:** identity has no secret, least privilege, and a leaver doesn't force a key rotation; disable the person's account, the app's identity is separate.
- **SAS from a backend:** backend (managed identity, Storage Blob Delegator + data role) fetches a user delegation key occasionally and signs short-lived SAS tokens locally per user action.
- **Lesson learned:** the activity log can lag a few minutes, so a new resource may not show its creator right away.
- **Lab:** `infra/lab5-identity.bicep` (empty group); user, group and role assignments done in the portal. All deleted (group, user, resource group).

## Questions
-
