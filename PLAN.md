# Azure Fundamentals + AI-103 Project Plan

**Exam:** AI-103 *Developing AI Apps and Agents on Azure* (leads to Azure AI Apps and Agents Developer Associate; replaces the retired AI-102).
**Source of truth:** Microsoft Learn AI-103 study guide, "skills measured as of April 16, 2026" (page last updated Nov 5, 2026). Passing score 700.
**Goal:** Learn Azure fundamentals (AZ-900 level) and every AI-103 domain by building one capstone, then pass AI-103. **Only AI-103 will be sat; AZ-900 is study material, not an exam to book.**
**Duration:** 12 weeks at about 8-10 hrs/week. Compress or stretch as needed.
**Caveats:** Exam questions mostly cover GA features, but some Preview features can appear. Re-check the study guide at Weeks 4 and 10. Confirm exam availability, languages and price on the Exam Details page before booking.

> Note: AI-103 is built around **Microsoft Foundry, LLMs and agents**. Classic services (Custom Vision, CLU, custom question answering, Language Studio projects) are no longer listed in the outline, so this plan treats them as optional background only.

---

## 1. Capstone: "DocuMind" - Document and Support Agent

Users upload documents, images, audio and video. DocuMind extracts and enriches them, indexes them for retrieval, and exposes an **agent** that answers questions with citations, describes media, and takes actions with approvals.

```
Web UI (Static Web App)
  -> API (Functions / Container App)
       |- Foundry project (models, agents, evaluations, tracing)
       |    |- Orchestrator agent -> specialist agents (research, extraction, action)
       |    |- Tools: AI Search, Content Understanding, custom functions, speech
       |    -> Guardrails: content filters, prompt shields, approval flow
  -> Blob Storage -> Event Grid -> Function (ingest)
       |- Content Understanding analyzers (documents, images, audio, video)
       |- Document OCR / layout
       |- Translator / LLM extraction (entities, summaries, JSON)
       -> AI Search (skillset, vector + hybrid + semantic)
  -> Monitor, App Insights, Key Vault, Managed Identity, Bicep, GitHub Actions
```

### Repo layout
```
azure-project/
  PLAN.md
  infra/            # Bicep modules (from Phase 1)
  src/
    ingest/         # blob trigger, Content Understanding, indexing
    agents/         # agent definitions, tools, orchestration
    api/            # chat / RAG endpoints
    web/            # simple front end
    eval/           # test sets, evaluators, safety evals
  labs/             # throwaway per-topic experiments
  notes/            # weekN.md
  .github/workflows/
```

---

## 2. Ground rules (cost and safety)
- **Day 1:** budget alerts in Cost Management at $5, $20 and 80% of your credit.
- **One resource group per phase;** delete it when the phase ends (keep `rg-docmind-core`).
- **Free or cheap tiers:** Functions Consumption, Static Web Apps Free, App Service F1, AI Search Free, Foundry Tools F0 where offered. Model calls cost tokens, so use small prompts, small test sets, and the cheapest suitable model.
- **Deployments cost while they exist.** Delete provisioned or high-capacity model deployments after labs.
- **Video generation, fine-tuning and Provisioned throughput** are the costly items. Do them once, briefly, or read only.
- **No keys in git.** Use **keyless auth (Entra ID + Managed Identity)** from Phase 2 onward; it is also an exam topic.
- **Tags:** `project=docmind`, `phase=N`.
- **Region:** pick one that supports your needed models, AI Search and Content Understanding. Keep all resources there.
- **Language:** choose Python or C# and stay with it. Skim the other for code-reading questions.
- **Quota:** request model quota or access in Week 1; approvals can lag.

---

## 3. Phases

### Phase 0 - Setup (Week 1, first half)
| Task | Output |
|---|---|
| Create the free account, enable MFA | Subscription ready |
| Install Azure CLI, VS Code + Azure/Foundry extensions, Bicep, Git, Python/.NET | Local toolchain |
| Budget alerts; request model access/quota | Alerts, requests filed |
| Create the repo layout above | Git repo |

### Phase 1 - Azure fundamentals (Weeks 1-3)
**Concepts (AZ-900 domains):**
- **Cloud basics:** shared responsibility, IaaS/PaaS/SaaS, public/private/hybrid, CapEx vs OpEx, consumption pricing, high availability, scalability, elasticity, reliability, predictability, governance, security.
- **Core architecture:** regions, region pairs, availability zones, resource groups, subscriptions, management groups, ARM.
- **Compute:** VMs, scale sets, App Service, Functions, Container Apps/ACI, AKS (concepts).
- **Networking:** VNet, subnets, NSG, peering, VPN/ExpressRoute (concepts), DNS, Load Balancer, Application Gateway, Private Endpoints.
- **Storage:** Blob, Files, Queue, Table, redundancy (LRS/ZRS/GRS), access tiers, SAS, lifecycle policies.
- **Databases:** SQL Database, Cosmos DB, PostgreSQL/MySQL (concepts).
- **Identity and security:** Entra ID, Conditional Access, RBAC, Managed Identity, Key Vault, Defender for Cloud, Zero Trust.
- **Governance:** Policy, Locks, Tags, landing zones, Purview.
- **Cost:** pricing factors, calculator, TCO, Cost Management, reservations, SLAs.
- **Management:** Portal, Cloud Shell, CLI, PowerShell, ARM/Bicep, Arc, Monitor, Advisor, Service Health.

**Labs (`rg-docmind-core`):**
1. Resource group, tags, Policy (require tag), Delete lock.
2. Entra: test user and group; RBAC (Reader/Contributor) at RG scope.
3. Storage account: container, upload, SAS, lifecycle rule, pick redundancy.
4. Key Vault secret read through Managed Identity from a Function.
5. VNet + subnet + NSG; a B1s VM (stop it afterwards); Static Web App deploy.
6. Redo labs 1-3 in **Bicep**; deploy with `az deployment group create`.
7. Log Analytics + Application Insights; write a KQL query.
8. Cost Management view, budget, and Pricing Calculator estimate for the full capstone.

**Milestone:** `infra/` deploys the core RG. Optional self-check: 80%+ on the free Microsoft Learn AZ-900 practice assessment (no need to sit the exam).

**Week 1 daily schedule (learn + a free hands-on task every day):**
| Day | Learn | Practical (free) |
|---|---|---|
| 1 | Cloud models, shared responsibility | Budget alert, CLI sign-in check (done) |
| 2 | Benefits: scalability, elasticity, high availability | `az account list-locations`, pick a region; view App Service scale options in the portal without creating anything |
| 3 | IaaS, PaaS, SaaS, consumption pricing | Create `rg-learning-lab1` with tags `project`, `phase` from the CLI |
| 4 | Regions, region pairs, availability zones | Assign built-in Policy "Require a tag" to the group; watch a resource creation get denied |
| 5 | Resource groups, subscriptions, ARM | Add a Delete lock; try to delete the group and see it blocked |
| 6 | Review, knowledge checks | Redo group + tags + lock in Bicep, deploy, then delete the group |
| 7 | Rest or practice assessment | Pricing Calculator estimate for a small web app; write notes |

All Week 1 tasks use only free features (resource groups, tags, Policy, locks, CLI, calculator). No VM, storage or model is created.

### Phase 2 - Foundry foundation: plan, deploy, secure (Week 4)
*AI-103 domain: Plan and manage an Azure AI solution (25-30%)*
- **Choose services and models:** LLMs vs small language models vs multimodal vs code models vs Foundry Tools; retrieval and indexing methods; memory, tool and knowledge integration for agents.
- **Set up in Foundry:** design infrastructure for AI apps and agents; deployment options (Standard, Global, Provisioned, Data Zone); configure model and agent deployments; connect a Foundry project to CI/CD.
- **Manage and secure:** quotas, scaling, rate limits, cost footprint; **managed identity, keyless credentials, private networking, role policies**.
- Labs:
  1. Deploy a Foundry resource and project with **Bicep**; deploy a chat model and an embedding model.
  2. Compare two or three models on the same prompts (quality, latency, tokens, price); write a one-page model-selection note.
  3. Call models with the **Foundry SDK**, authenticated with Entra ID (no keys); assign the least-privilege role.
  4. Hit a rate limit on purpose; implement retry with backoff; read quota and TPM settings.
  5. Add a Key Vault reference and disable local (key) auth on the resource.
  6. Private endpoint and network restrictions (try one; concept for the rest).
  7. GitHub Actions: `bicep build` -> deploy dev RG -> smoke test the model call.
- **Milestone:** keyless chat call from code, deployed through CI/CD, with quota and cost notes.

### Phase 3 - Information extraction (Week 5)
*AI-103 domain: Implement information extraction solutions (10-15%)*
- **Content Understanding:** analyzers for documents, images, audio and video; single-task vs pro mode; structured (JSON) vs markdown output; clean grounded representations for RAG.
- **Document OCR and layout:** OCR + layout analysis + field extraction in one multimodal pipeline.
- Labs:
  1. Create a Content Understanding analyzer for documents (invoice or report) with a field schema; output JSON and markdown.
  2. Run analyzers on an image, an audio file and a short video.
  3. Compare single-task and pro-mode analyzers on the same inputs.
  4. Build the ingest Function: Blob trigger -> analyzer -> store results.
  5. Compare with a plain OCR/layout call; note when each fits.
- **Milestone:** every upload type becomes structured output plus markdown in storage.

### Phase 4 - Retrieval and grounding (Week 6)
*AI-103 domains: Information extraction (retrieval half) + Generative apps (RAG, evaluation)*
- **AI Search:** ingest and index docs, images, audio, video content; **vector, hybrid and semantic search**; enrichment with built-in and custom skills for text, images and layout; RAG ingestion flow with OCR; index health monitoring.
- **RAG:** retrieval in an application; connect retrieval to workflows and agent tools; evaluate fabrication, relevance, quality, safety.
- Labs:
  1. Create an index (Free tier) over the Content Understanding output; add embeddings and vector fields.
  2. Add a skillset (OCR, image, layout) and a **custom skill** (Function).
  3. Run keyword, vector, hybrid and semantic queries; compare relevance on 15-20 test questions.
  4. Build the RAG endpoint: query -> retrieval -> grounded prompt -> answer with citations.
  5. Create `eval/`: a test set; run evaluators for groundedness, relevance and fabrication; log scores.
  6. Monitor ingestion quality and index health (indexer status, failed docs, query metrics).
- **Milestone:** a RAG API with citations, plus a baseline evaluation report.

### Phase 5 - Text analysis and speech (Week 7)
*AI-103 domain: Implement text analysis solutions (10-15%)*
- **LLM text analysis:** entities, topics, summaries, **structured JSON output** by prompting; sentiment, tone, safety and sensitive-content detection; domain customization (e.g. compliance summarization); **Translator** and LLM-powered translation.
- **Speech:** speech-to-text and text-to-speech for agents; **speech as an agent modality** including custom speech; multimodal reasoning on audio inputs; speech translation with models and Foundry Tools.
- Labs:
  1. Prompt for entities, topics and summaries as strict JSON (schema/structured outputs); validate and handle bad JSON.
  2. Detect sentiment, tone and sensitive content; redact before indexing.
  3. Translate with Azure Translator and with an LLM; compare quality, cost and latency.
  4. Domain summarizer (e.g. compliance summary) with a rubric to score it.
  5. Speech to text and text to speech; wire both into a voice interaction with the API.
  6. Send audio to a multimodal model for reasoning; try speech translation.
  7. Custom speech: read the process and, if credits allow, run a tiny lab.
- **Milestone:** audio or text in any language is analyzed, safe and searchable; voice works with the API.

### Phase 6 - Vision, multimodal and generation (Week 8)
*AI-103 domain: Implement computer vision solutions (10-15%)*
- **Image and video generation:** text-to-image, text-to-video, reference media, inpainting and mask-based edits, editing generated videos, generation and editing controls.
- **Multimodal understanding:** captions (concise vs detailed, single or multiple images), visual question answering with grounded evidence, alt-text for accessibility, Content Understanding for visual characteristics, video analysis of segments, identifying objects and regions.
- **Responsible AI for multimodal:** unsafe visual content filters, **indirect prompt injection via text embedded in images**, visual policy rules (watermarks, prohibited symbols, brand rules).
- Labs:
  1. Caption images (concise and detailed) with a multimodal model; batch multiple images in one prompt.
  2. Visual QA grounded in the image, with an instruction to answer "not visible" when unsure.
  3. Generate alt-text and extended descriptions; check against an accessibility checklist.
  4. Content Understanding: a visual analyzer, then a video analyzer on segments.
  5. Detect objects and regions (bounding boxes) with a multimodal model.
  6. Generate an image from a prompt and a reference image; edit with a mask (inpainting).
  7. Video generation and editing: one short run if available and affordable; otherwise read the docs.
  8. Test an image with embedded instructions ("ignore previous...") against your safeguards; apply image content filters and a watermark/brand rule.
- **Milestone:** DocuMind describes, answers questions about and safely handles images and video.

### Phase 7 - Agents I: build a single agent (Week 9)
*AI-103 domain: Implement generative AI and agentic solutions (30-35%), "Build agents"*
- Define roles, goals, conversation tracking, tool schemas.
- Integrate retrieval, function calling and conversation memory.
- Tools: APIs, knowledge stores, search, Content Understanding, custom functions.
- Labs:
  1. Create an agent in the Foundry Agent Service with instructions and a role.
  2. Add the AI Search tool (grounding) and a Content Understanding tool.
  3. Add custom function tools (`create_ticket`, `lookup_status`); define schemas strictly.
  4. Conversation memory: threads, long-term memory, trimming context.
  5. Observe tool calls and failures through traces; fix schema mistakes.
- **Milestone:** one agent answers with citations, calls tools, and remembers context.

### Phase 8 - Agents II: orchestration, autonomy and optimization (Week 10)
*Same domain: multi-agent, safeguards, optimization*
- **Multi-agent orchestration:** orchestrator + specialists; hand-offs; shared state.
- **Autonomous or semi-autonomous workflows** with safeguards and **approval flows**.
- **Monitoring and error analysis** of deployed agents.
- **Optimization:** prompt engineering, parameters (temperature, top_p, max tokens), **model reflection, chain-of-thought evaluations, self-critique loops**; orchestrating several models, flows or LLM + rules hybrids.
- Labs:
  1. Split into three agents (research, extraction, action) with an orchestrator.
  2. Add a human approval step before write actions (ticket creation).
  3. Evaluate agent behavior: task success, tool-call accuracy, error analysis on 20 scenarios.
  4. Add a self-critique loop to answers; measure whether groundedness improves and what it costs.
  5. Route cheap queries to a small model and hard ones to a larger model; add a rules pre-filter.
  6. Tune parameters on the eval set; record the best settings.
- **Milestone:** a multi-agent flow with approvals, an evaluation report, and a documented optimization trade-off.

### Phase 9 - Responsible AI, observability and operations (Week 11)
*AI-103 domains: Plan and manage (responsible AI, monitoring) + Optimize and operationalize*
- **Responsible AI:** safety filters, guardrails, risk detection, content moderation; evaluators, safety evaluations, explanation tooling; **auditing** via trace logging, provenance metadata and approvals; governing agent behavior with oversight modes, constraints and **tool-access controls**.
- **Observability:** tracing, token analytics, safety signals, latency breakdowns; monitoring model performance, **drift**, safety events, grounding quality.
- Labs:
  1. Configure content filters, blocklists and prompt shields; run red-team prompts and record outcomes.
  2. Run Foundry safety evaluations and quality evaluators; store results per version.
  3. Enable tracing to App Insights; build a dashboard (tokens, latency, errors, filter hits).
  4. Alerts: 429s, high cost per request, safety events, grounding score drop.
  5. Provenance metadata and audit logging for agent actions; write the approval policy.
  6. Tool-access controls: least-privilege per agent; deny by default.
  7. Cost review: tokens per feature, quota and scaling plan, budget alerts per RG.
- **Milestone:** dashboard, alerts, safety-eval results, and a one-page governance policy.

### Phase 10 - Production hardening and exam prep (Week 12)
- CI/CD with GitHub Actions: build, deploy, run `eval/` as a gate.
- Azure Policy for allowed regions/SKUs; resource locks on core; RBAC review; Defender for Cloud recommendations.
- Write `README.md`: architecture diagram, cost estimate, security notes, runbook.
- Exam prep:
  - Take the free **Microsoft Learn practice assessment** plus one paid practice exam. Review every wrong answer.
  - Walk the study guide bullet by bullet (Section 6) and ask "can I do this from memory?".
  - Practice Microsoft Learn search, which is available during the exam.
  - Drill code reading (Foundry SDK, agents, Search queries, function-calling schemas).
  - Book the exam after two practice scores of 85% or more.

---

## 4. Weekly schedule at a glance
| Week | Focus | Deliverable |
|---|---|---|
| 1 | Setup + fundamentals (cloud basics, architecture) | Core RG, tags, policy, RBAC |
| 2 | Compute, networking, storage, identity | Storage, Key Vault, VNet labs |
| 3 | Governance, cost, management, Bicep | Bicep core infra; optional AZ-900 practice check |
| 4 | Foundry setup, models, deployment, security | Keyless call via CI/CD |
| 5 | Content Understanding + OCR | Multimodal ingest pipeline |
| 6 | AI Search + RAG + evaluation | RAG API + baseline eval |
| 7 | LLM text analysis, Translator, speech | Text and voice pipeline |
| 8 | Vision, multimodal, generation, visual safety | Image and video features |
| 9 | Single agent | Tool-using agent with memory |
| 10 | Multi-agent, approvals, optimization | Orchestrated agents + eval report |
| 11 | Responsible AI, observability, ops | Dashboard, alerts, governance |
| 12 | Hardening + exam prep | CI/CD, README, practice 85%+ |

## 5. Weekly routine
- **Learn (2-3 hrs):** Microsoft Learn module or video.
- **Build (4-5 hrs):** labs, committed to the repo.
- **Review (1 hr):** `notes/weekN.md` covering what it is, when to use it, how it is priced, and one gotcha.
- **Clean up (10 min):** delete lab RGs and unused model deployments; check Cost Management.

---

## 6. AI-103 coverage checklist (study guide, April 16, 2026)

**Plan and manage an Azure AI solution (25-30%)** - Phase 2, 9, 10
- [ ] Choose a model per task (LLM, SLM, multimodal, Foundry Tools)
- [ ] Choose Foundry services for generation, grounding, vector search, agent workflows, multimodal
- [ ] Choose a retrieval and indexing method
- [ ] Choose memory, tool and knowledge integrations for agents
- [ ] Design Azure infrastructure for AI apps and agents
- [ ] Choose deployment options; configure model and agent deployments
- [ ] Integrate Foundry projects with CI/CD
- [ ] Manage quotas, scaling, rate limits and cost
- [ ] Monitor performance, drift, safety events, grounding quality
- [ ] Monitor ingestion quality, index health, relevance
- [ ] Security: managed identity, private networking, keyless credentials, role policies
- [ ] Safety filters, guardrails, risk detection, content moderation
- [ ] Responsible AI instrumentation: evaluators, safety evals, explanation tooling
- [ ] Auditing: trace logs, provenance metadata, approval workflows
- [ ] Govern agent behavior: oversight modes, constraints, tool-access controls

**Implement generative AI and agentic solutions (30-35%)** - Phase 4, 7, 8, 9
- [ ] Deploy and consume LLMs, small, code and multimodal models
- [ ] Implement RAG in an application
- [ ] Design workflows, tool-augmented flows, multistep reasoning pipelines
- [ ] Evaluate models and apps (fabrication, relevance, quality, safety)
- [ ] Integrate with Foundry SDKs and connectors; connect an app to a Foundry project
- [ ] Define agent roles, goals, conversation tracking, tool schemas
- [ ] Agents with retrieval, function calling and memory
- [ ] Integrate agent tools (APIs, knowledge stores, search, Content Understanding, custom functions)
- [ ] Orchestrated multi-agent solutions
- [ ] Autonomous or semi-autonomous workflows with safeguards and approvals
- [ ] Monitor deployed agents; evaluate behavior; error analysis
- [ ] Prompt engineering and parameter tuning
- [ ] Model reflection, chain-of-thought evaluation, self-critique loops
- [ ] Observability: tracing, token analytics, safety signals, latency breakdowns
- [ ] Orchestrate multiple models, flows, or hybrid LLM + rules

**Implement computer vision solutions (10-15%)** - Phase 6
- [ ] Text-to-image and reference-media image generation
- [ ] Text-to-video and reference-media video generation
- [ ] Image editing: inpainting, mask edits, prompt edits
- [ ] Edit generated videos; apply generation and editing controls
- [ ] Multimodal analysis of visual context
- [ ] Concise and detailed captions (single or multiple images)
- [ ] Visual question answering grounded in evidence
- [ ] Alt-text and extended descriptions per accessibility guidelines
- [ ] Content Understanding for visual characteristics; single-task and pro-mode pipelines
- [ ] Video segment analysis
- [ ] Identify objects, components, regions
- [ ] Unsafe visual content filters
- [ ] Indirect prompt injection via text in images
- [ ] Visual policy rules: watermarks, prohibited symbols, brand usage

**Implement text analysis solutions (10-15%)** - Phase 5
- [ ] Entities, topics, summaries, structured JSON via prompting and Foundry Tools
- [ ] Sentiment, tone, safety, sensitive content
- [ ] Translation with Azure Translator or LLM flows
- [ ] Domain customization (e.g. compliance summarization)
- [ ] Speech-to-text and text-to-speech for agents
- [ ] Speech as an agent modality, incl. custom speech models
- [ ] Multimodal reasoning on audio
- [ ] Speech translation with models and Foundry Tools

**Implement information extraction solutions (10-15%)** - Phase 3, 4
- [ ] Ingest and index documents, images, audio, video
- [ ] Semantic, hybrid and vector search for grounding
- [ ] Enrichment with custom or built-in skills (text, images, layout)
- [ ] RAG ingestion flow with OCR
- [ ] Connect retrieval to workflows and agent tools
- [ ] Multimodal extraction pipelines: OCR, layout, field extraction
- [ ] Clean grounded representations for agents and RAG via Content Understanding
- [ ] Content Understanding analyzers for structured or markdown output

## 7. Fundamentals checklist (AZ-900 topics; study only, no exam)
- [ ] Cloud concepts (benefits, service and deployment models, shared responsibility)
- [ ] Core architecture (regions, AZs, RGs, subscriptions, ARM)
- [ ] Compute and networking
- [ ] Storage and databases
- [ ] Identity, access and security
- [ ] Governance and compliance (Policy, Locks, Purview)
- [ ] Cost management and SLAs
- [ ] Management and monitoring tools

## 8. Risks and mitigations
| Risk | Mitigation |
|---|---|
| Surprise charges (tokens, video generation, provisioned deployments) | Budgets, small test sets, delete deployments and RGs after labs, weekly cost check |
| Model quota, region or access limits | Request access in Week 1; pick a region that supports everything; use available catalog models as substitutes |
| Preview features change or disappear | Learn the concepts and GA paths first; re-check the study guide at Weeks 4 and 10 |
| Free tier limits (AI Search 50 MB) | Small sample documents; recreate services to reset |
| Exam logistics unclear (new exam) | Check the Exam Details page for language, price and scheduling before booking |
| Falling behind | Drop optional labs first: video generation, custom speech, private endpoints, classic services |

## 9. Optional background (not in the AI-103 outline)
Classic services that were part of AI-102: Custom Vision, Conversational Language Understanding, custom question answering, Custom Translator, Spatial Analysis, Video Indexer. Skip them unless a project needs them.
