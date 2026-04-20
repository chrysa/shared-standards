# Chrysa Development Hub (Notion Reorganized)

## Architecture Overview

```xml
<?xml version="1.0" encoding="UTF-8"?>
<svg viewBox="0 0 1200 800" xmlns="http://www.w3.org/2000/svg">
  <!-- Background -->
  <rect width="1200" height="800" fill="#f5f5f5"/>

  <!-- Central Hub -->
  <rect x="500" y="350" width="200" height="100" fill="#2563eb" rx="8"/>
  <text x="600" y="405" font-size="18" font-weight="bold" fill="white" text-anchor="middle">Notion Hub</text>

  <!-- Layer 1: Optimization & Strategy -->
  <g id="layer1">
    <rect x="50" y="50" width="150" height="80" fill="#7c3aed" rx="6"/>
    <text x="125" y="95" font-size="14" font-weight="bold" fill="white" text-anchor="middle">Claude</text>
    <text x="125" y="112" font-size="14" font-weight="bold" fill="white" text-anchor="middle">Optimization</text>
    <line x1="200" y1="90" x2="500" y2="390" stroke="#666" stroke-width="2"/>
  </g>

  <!-- Layer 2: Architecture & Projects -->
  <g id="layer2">
    <rect x="1000" y="50" width="150" height="80" fill="#0891b2" rx="6"/>
    <text x="1075" y="95" font-size="14" font-weight="bold" fill="white" text-anchor="middle">Ecosystem</text>
    <text x="1075" y="112" font-size="14" font-weight="bold" fill="white" text-anchor="middle">Architecture</text>
    <line x1="1000" y1="90" x2="700" y2="390" stroke="#666" stroke-width="2"/>
  </g>

  <!-- Layer 3: Game Dev Config -->
  <g id="layer3">
    <rect x="50" y="250" width="150" height="80" fill="#ea580c" rx="6"/>
    <text x="125" y="295" font-size="14" font-weight="bold" fill="white" text-anchor="middle">Game Dev</text>
    <text x="125" y="312" font-size="14" font-weight="bold" fill="white" text-anchor="middle">Config</text>
    <line x1="200" y1="290" x2="500" y2="380" stroke="#666" stroke-width="2"/>
  </g>

  <!-- Layer 4: Conflict Detection -->
  <g id="layer4">
    <rect x="1000" y="250" width="150" height="80" fill="#c2410c" rx="6"/>
    <text x="1075" y="295" font-size="14" font-weight="bold" fill="white" text-anchor="middle">Dev-Nexus</text>
    <text x="1075" y="312" font-size="14" font-weight="bold" fill="white" text-anchor="middle">Conflicts</text>
    <line x1="1000" y1="290" x2="700" y2="380" stroke="#666" stroke-width="2"/>
  </g>

  <!-- Sub-items from Hub -->
  <g id="sub-items">
    <rect x="350" y="500" width="140" height="70" fill="#059669" rx="5"/>
    <text x="420" y="535" font-size="12" fill="white" text-anchor="middle">Dependencies</text>
    <text x="420" y="552" font-size="12" fill="white" text-anchor="middle">Macro/Micro</text>
    <line x1="420" y1="500" x2="600" y2="450" stroke="#666" stroke-width="1.5"/>

    <rect x="550" y="500" width="140" height="70" fill="#059669" rx="5"/>
    <text x="620" y="535" font-size="12" fill="white" text-anchor="middle">Project</text>
    <text x="620" y="552" font-size="12" fill="white" text-anchor="middle">Structure</text>
    <line x1="620" y1="500" x2="600" y2="450" stroke="#666" stroke-width="1.5"/>

    <rect x="750" y="500" width="140" height="70" fill="#059669" rx="5"/>
    <text x="820" y="535" font-size="12" fill="white" text-anchor="middle">Workflow</text>
    <text x="820" y="552" font-size="12" fill="white" text-anchor="middle">Standards</text>
    <line x1="820" y1="500" x2="600" y2="450" stroke="#666" stroke-width="1.5"/>
  </g>

  <!-- Legend -->
  <g id="legend">
    <text x="50" y="720" font-size="12" font-weight="bold">Legend:</text>
    <rect x="50" y="730" width="20" height="20" fill="#7c3aed"/>
    <text x="80" y="745" font-size="11">Strategy</text>

    <rect x="250" y="730" width="20" height="20" fill="#0891b2"/>
    <text x="280" y="745" font-size="11">Architecture</text>

    <rect x="480" y="730" width="20" height="20" fill="#ea580c"/>
    <text x="510" y="745" font-size="11">Game Dev</text>

    <rect x="680" y="730" width="20" height="20" fill="#c2410c"/>
    <text x="710" y="745" font-size="11">DevOps/QA</text>

    <rect x="880" y="730" width="20" height="20" fill="#059669"/>
    <text x="910" y="745" font-size="11">Utilities</text>
  </g>
</svg>
```

---

## New Notion Structure

### 1. **Claude Optimization Hub** (Sub-page)
   - Cost analysis by model
   - Task-to-model routing matrix
   - Context optimization rules
   - Monthly cost projections
   - Implementation checklist
   - **Game Dev Special Cases** (Blender + Unity routing)
   - **Red flags** for cost overruns

### 2. **Ecosystem Architecture Hub** (Sub-page)
   - **Macro Graph**: Final products + dependencies (SVG)
   - **Micro Graph**: All 41 projects + connections (SVG)
   - **Service Map**: Backend services topology (SVG)
   - **Database Layer**: PostgreSQL, Redis, MongoDB schemas
   - **Integration Points**: How products connect to backends
   - **Maturity Matrix**: Production / MVP / Alpha / Concept

### 3. **Game Development Configuration** (Sub-page)
   - **Blender Integration**: Asset pipeline, shader generation, UV automation
   - **Unity Integration**: C# code generation, physics setup, UI system
   - **Claude.md for Games**: Game-dev specific rules
   - **Asset Pipeline**: Generated models, textures, configs
   - **Performance Budget**: Frame time, memory, draw calls
   - **Networking**: Multiplayer sync, state management

### 4. **Dev-Nexus Conflict Detection** (Sub-page)
   - **Conflict Rules**: Local vs open PR detection
   - **Auto-detection**: Branch conflicts, file conflicts
   - **Alert System**: Notify when local changes conflict with open PRs
   - **Resolution Strategies**: Merge strategies, rebase rules
   - **CI Integration**: Block merges on unresolved conflicts

### 5. **Project Structure & Standards** (Sub-page)
   - CLAUDE.md template
   - routes.md structure
   - schema.md format
   - components.md layout
   - architecture.md guidelines

### 6. **Workflows & Checklists** (Sub-page)
   - Feature development workflow
   - Bug fix workflow
   - Game asset creation workflow
   - Code review checklist
   - Pre-commit validation

---

## Dependencies: Macro View (SVG)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<svg viewBox="0 0 1400 900" xmlns="http://www.w3.org/2000/svg">
  <!-- Title -->
  <text x="700" y="30" font-size="24" font-weight="bold" text-anchor="middle">Chrysa Macro: Products → Platforms → Infrastructure</text>

  <!-- TIER 1: FINAL PRODUCTS -->
  <g id="products">
    <text x="700" y="80" font-size="16" font-weight="bold" text-anchor="middle" fill="#1f2937">Tier 1: End-User Products (12)</text>

    <!-- Row 1 -->
    <rect x="50" y="110" width="110" height="60" fill="#10b981" rx="4"/>
    <text x="105" y="140" font-size="11" font-weight="bold" fill="white" text-anchor="middle">my-assistant</text>
    <text x="105" y="155" font-size="9" fill="white" text-anchor="middle">(Desktop AI)</text>

    <rect x="180" y="110" width="110" height="60" fill="#10b981" rx="4"/>
    <text x="235" y="140" font-size="11" font-weight="bold" fill="white" text-anchor="middle">lifeos</text>
    <text x="235" y="155" font-size="9" fill="white" text-anchor="middle">(AI Successor)</text>

    <rect x="310" y="110" width="110" height="60" fill="#10b981" rx="4"/>
    <text x="365" y="140" font-size="11" font-weight="bold" fill="white" text-anchor="middle">my-fridge</text>
    <text x="365" y="155" font-size="9" fill="white" text-anchor="middle">(Grocery)</text>

    <rect x="440" y="110" width="110" height="60" fill="#10b981" rx="4"/>
    <text x="495" y="140" font-size="11" font-weight="bold" fill="white" text-anchor="middle">diy-stream-deck</text>
    <text x="495" y="155" font-size="9" fill="white" text-anchor="middle">(Hardware)</text>

    <rect x="570" y="110" width="110" height="60" fill="#10b981" rx="4"/>
    <text x="625" y="140" font-size="11" font-weight="bold" fill="white" text-anchor="middle">satisfactory-calc</text>
    <text x="625" y="155" font-size="9" fill="white" text-anchor="middle">(Game Tools)</text>

    <!-- Row 2 -->
    <rect x="700" y="110" width="110" height="60" fill="#10b981" rx="4"/>
    <text x="755" y="140" font-size="11" font-weight="bold" fill="white" text-anchor="middle">genealogy-val</text>
    <text x="755" y="155" font-size="9" fill="white" text-anchor="middle">(Data)</text>

    <rect x="830" y="110" width="110" height="60" fill="#10b981" rx="4"/>
    <text x="885" y="140" font-size="11" font-weight="bold" fill="white" text-anchor="middle">linkendin-resume</text>
    <text x="885" y="155" font-size="9" fill="white" text-anchor="middle">(CV Builder)</text>

    <rect x="960" y="110" width="110" height="60" fill="#10b981" rx="4"/>
    <text x="1015" y="140" font-size="11" font-weight="bold" fill="white" text-anchor="middle">PO-GO-DEX</text>
    <text x="1015" y="155" font-size="9" fill="white" text-anchor="middle">(Pokémon)</text>

    <rect x="1090" y="110" width="110" height="60" fill="#10b981" rx="4"/>
    <text x="1145" y="140" font-size="11" font-weight="bold" fill="white" text-anchor="middle">+4 more...</text>
    <text x="1145" y="155" font-size="9" fill="white" text-anchor="middle">(tools, games)</text>
  </g>

  <!-- ARROWS DOWN -->
  <g id="arrows1">
    <line x1="105" y1="170" x2="105" y2="200" stroke="#666" stroke-width="2" marker-end="url(#arrowhead)"/>
    <line x1="235" y1="170" x2="235" y2="200" stroke="#666" stroke-width="2" marker-end="url(#arrowhead)"/>
    <line x1="365" y1="170" x2="365" y2="200" stroke="#666" stroke-width="2" marker-end="url(#arrowhead)"/>
    <line x1="495" y1="170" x2="495" y2="200" stroke="#666" stroke-width="2" marker-end="url(#arrowhead)"/>
  </g>

  <!-- TIER 2: PLATFORM SERVICES -->
  <g id="platforms">
    <text x="700" y="240" font-size="16" font-weight="bold" text-anchor="middle" fill="#1f2937">Tier 2: Platform Services (4)</text>

    <rect x="100" y="260" width="140" height="70" fill="#3b82f6" rx="4"/>
    <text x="170" y="290" font-size="12" font-weight="bold" fill="white" text-anchor="middle">ai-aggregator</text>
    <text x="170" y="308" font-size="9" fill="white" text-anchor="middle">(LLM Router)</text>
    <text x="170" y="321" font-size="8" fill="white" text-anchor="middle">OpenAI, Anthropic</text>

    <rect x="320" y="260" width="140" height="70" fill="#3b82f6" rx="4"/>
    <text x="390" y="290" font-size="12" font-weight="bold" fill="white" text-anchor="middle">dev-nexus</text>
    <text x="390" y="308" font-size="9" fill="white" text-anchor="middle">(Dashboard)</text>
    <text x="390" y="321" font-size="8" fill="white" text-anchor="middle">Project Visibility</text>

    <rect x="540" y="260" width="140" height="70" fill="#3b82f6" rx="4"/>
    <text x="610" y="290" font-size="12" font-weight="bold" fill="white" text-anchor="middle">discord-bot-back</text>
    <text x="610" y="308" font-size="9" fill="white" text-anchor="middle">(Events)</text>
    <text x="610" y="321" font-size="8" fill="white" text-anchor="middle">Discord Integration</text>

    <rect x="760" y="260" width="140" height="70" fill="#3b82f6" rx="4"/>
    <text x="830" y="290" font-size="12" font-weight="bold" fill="white" text-anchor="middle">notion-automation</text>
    <text x="830" y="308" font-size="9" fill="white" text-anchor="middle">(Sync)</text>
    <text x="830" y="321" font-size="8" fill="white" text-anchor="middle">Notion ↔ GitHub</text>
  </g>

  <!-- ARROWS DOWN -->
  <g id="arrows2">
    <line x1="170" y1="330" x2="170" y2="360" stroke="#666" stroke-width="2" marker-end="url(#arrowhead)"/>
    <line x1="390" y1="330" x2="390" y2="360" stroke="#666" stroke-width="2" marker-end="url(#arrowhead)"/>
    <line x1="610" y1="330" x2="610" y2="360" stroke="#666" stroke-width="2" marker-end="url(#arrowhead)"/>
    <line x1="830" y1="330" x2="830" y2="360" stroke="#666" stroke-width="2" marker-end="url(#arrowhead)"/>
  </g>

  <!-- TIER 3: SHARED LIBS & CONFIG -->
  <g id="libs">
    <text x="700" y="410" font-size="16" font-weight="bold" text-anchor="middle" fill="#1f2937">Tier 3: Shared Libraries & Config (4)</text>

    <rect x="150" y="430" width="140" height="70" fill="#8b5cf6" rx="4"/>
    <text x="220" y="460" font-size="12" font-weight="bold" fill="white" text-anchor="middle">chrysa-lib</text>
    <text x="220" y="478" font-size="9" fill="white" text-anchor="middle">(Auth, APIs, Utils)</text>
    <text x="220" y="491" font-size="8" fill="white" text-anchor="middle">5 shared packages</text>

    <rect x="370" y="430" width="140" height="70" fill="#8b5cf6" rx="4"/>
    <text x="440" y="460" font-size="12" font-weight="bold" fill="white" text-anchor="middle">shared-standards</text>
    <text x="440" y="478" font-size="9" fill="white" text-anchor="middle">(Hooks, Workflows)</text>
    <text x="440" y="491" font-size="8" fill="white" text-anchor="middle">Global CI/CD</text>

    <rect x="590" y="430" width="140" height="70" fill="#8b5cf6" rx="4"/>
    <text x="660" y="460" font-size="12" font-weight="bold" fill="white" text-anchor="middle">agent-config</text>
    <text x="660" y="478" font-size="9" fill="white" text-anchor="middle">(MCP, Prompts)</text>
    <text x="660" y="491" font-size="8" fill="white" text-anchor="middle">AI Agent Setup</text>

    <rect x="810" y="430" width="140" height="70" fill="#8b5cf6" rx="4"/>
    <text x="880" y="460" font-size="12" font-weight="bold" fill="white" text-anchor="middle">github-actions</text>
    <text x="880" y="478" font-size="9" fill="white" text-anchor="middle">(Custom Actions)</text>
    <text x="880" y="491" font-size="8" fill="white" text-anchor="middle">Reusable CI Steps</text>
  </g>

  <!-- ARROWS DOWN -->
  <g id="arrows3">
    <line x1="220" y1="500" x2="220" y2="530" stroke="#666" stroke-width="2" marker-end="url(#arrowhead)"/>
    <line x1="440" y1="500" x2="440" y2="530" stroke="#666" stroke-width="2" marker-end="url(#arrowhead)"/>
    <line x1="660" y1="500" x2="660" y2="530" stroke="#666" stroke-width="2" marker-end="url(#arrowhead)"/>
    <line x1="880" y1="500" x2="880" y2="530" stroke="#666" stroke-width="2" marker-end="url(#arrowhead)"/>
  </g>

  <!-- TIER 4: INFRASTRUCTURE -->
  <g id="infra">
    <text x="700" y="580" font-size="16" font-weight="bold" text-anchor="middle" fill="#1f2937">Tier 4: Infrastructure</text>

    <rect x="250" y="600" width="140" height="70" fill="#f97316" rx="4"/>
    <text x="320" y="630" font-size="12" font-weight="bold" fill="white" text-anchor="middle">PostgreSQL 16</text>
    <text x="320" y="648" font-size="9" fill="white" text-anchor="middle">Primary Database</text>
    <text x="320" y="661" font-size="8" fill="white" text-anchor="middle">Projects, Users, Data</text>

    <rect x="470" y="600" width="140" height="70" fill="#f97316" rx="4"/>
    <text x="540" y="630" font-size="12" font-weight="bold" fill="white" text-anchor="middle">Redis 7</text>
    <text x="540" y="648" font-size="9" fill="white" text-anchor="middle">Cache & Sessions</text>
    <text x="540" y="661" font-size="8" fill="white" text-anchor="middle">Real-time Sync</text>

    <rect x="690" y="600" width="140" height="70" fill="#f97316" rx="4"/>
    <text x="760" y="630" font-size="12" font-weight="bold" fill="white" text-anchor="middle">MongoDB</text>
    <text x="760" y="648" font-size="9" fill="white" text-anchor="middle">Document Store</text>
    <text x="760" y="661" font-size="8" fill="white" text-anchor="middle">(Legacy Data)</text>

    <rect x="910" y="600" width="140" height="70" fill="#f97316" rx="4"/>
    <text x="980" y="630" font-size="12" font-weight="bold" fill="white" text-anchor="middle">k8s/Docker</text>
    <text x="980" y="648" font-size="9" fill="white" text-anchor="middle">Orchestration</text>
    <text x="980" y="661" font-size="8" fill="white" text-anchor="middle">Deployment</text>
  </g>

  <!-- Arrow marker definition -->
  <defs>
    <marker id="arrowhead" markerWidth="10" markerHeight="10" refX="5" refY="5" orient="auto">
      <polygon points="0 0, 10 5, 0 10" fill="#666" />
    </marker>
  </defs>
</svg>
```

---

## Dependencies: Micro View (All 41 Projects)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<svg viewBox="0 0 1600 1200" xmlns="http://www.w3.org/2000/svg">
  <text x="800" y="30" font-size="20" font-weight="bold" text-anchor="middle">Chrysa Micro: All 41 Projects Dependency Graph</text>

  <!-- Group 1: Foundation (3) -->
  <g id="foundation">
    <text x="100" y="80" font-size="12" font-weight="bold" fill="#7c3aed">Foundation</text>
    <rect x="20" y="100" width="120" height="50" fill="#7c3aed" rx="3" opacity="0.3"/>
    <text x="80" y="132" font-size="10" text-anchor="middle" font-weight="bold">agent-config</text>

    <rect x="160" y="100" width="120" height="50" fill="#7c3aed" rx="3" opacity="0.3"/>
    <text x="220" y="132" font-size="10" text-anchor="middle" font-weight="bold">shared-standards</text>

    <rect x="300" y="100" width="120" height="50" fill="#7c3aed" rx="3" opacity="0.3"/>
    <text x="360" y="132" font-size="10" text-anchor="middle" font-weight="bold">github-actions</text>
  </g>

  <!-- Group 2: Shared Libraries (5) -->
  <g id="libs">
    <text x="100" y="200" font-size="12" font-weight="bold" fill="#8b5cf6">Shared Libs</text>
    <rect x="20" y="220" width="100" height="45" fill="#8b5cf6" rx="3" opacity="0.3"/>
    <text x="70" y="247" font-size="9" text-anchor="middle">auth</text>

    <rect x="130" y="220" width="100" height="45" fill="#8b5cf6" rx="3" opacity="0.3"/>
    <text x="180" y="247" font-size="9" text-anchor="middle">api</text>

    <rect x="240" y="220" width="100" height="45" fill="#8b5cf6" rx="3" opacity="0.3"/>
    <text x="290" y="247" font-size="9" text-anchor="middle">utils</text>

    <rect x="350" y="220" width="100" height="45" fill="#8b5cf6" rx="3" opacity="0.3"/>
    <text x="400" y="247" font-size="9" text-anchor="middle">models</text>

    <rect x="460" y="220" width="100" height="45" fill="#8b5cf6" rx="3" opacity="0.3"/>
    <text x="510" y="247" font-size="9" text-anchor="middle">workflows</text>
  </g>

  <!-- Group 3: Backend Services (4) -->
  <g id="backends">
    <text x="700" y="80" font-size="12" font-weight="bold" fill="#3b82f6">Backend Services</text>
    <rect x="620" y="100" width="130" height="60" fill="#3b82f6" rx="3" opacity="0.3"/>
    <text x="685" y="135" font-size="10" text-anchor="middle" font-weight="bold">ai-aggregator</text>

    <rect x="770" y="100" width="130" height="60" fill="#3b82f6" rx="3" opacity="0.3"/>
    <text x="835" y="135" font-size="10" text-anchor="middle" font-weight="bold">dev-nexus</text>

    <rect x="920" y="100" width="130" height="60" fill="#3b82f6" rx="3" opacity="0.3"/>
    <text x="985" y="135" font-size="10" text-anchor="middle" font-weight="bold">discord-bot</text>

    <rect x="1070" y="100" width="130" height="60" fill="#3b82f6" rx="3" opacity="0.3"/>
    <text x="1135" y="135" font-size="10" text-anchor="middle" font-weight="bold">notion-auto</text>
  </g>

  <!-- Group 4: End-User Products (12) -->
  <g id="products">
    <text x="800" y="250" font-size="12" font-weight="bold" fill="#10b981">End-User Products</text>

    <!-- Row 1 -->
    <rect x="50" y="280" width="100" height="45" fill="#10b981" rx="3" opacity="0.3"/>
    <text x="100" y="307" font-size="9" text-anchor="middle">my-assistant</text>

    <rect x="160" y="280" width="100" height="45" fill="#10b981" rx="3" opacity="0.3"/>
    <text x="210" y="307" font-size="9" text-anchor="middle">lifeos</text>

    <rect x="270" y="280" width="100" height="45" fill="#10b981" rx="3" opacity="0.3"/>
    <text x="320" y="307" font-size="9" text-anchor="middle">my-fridge</text>

    <rect x="380" y="280" width="100" height="45" fill="#10b981" rx="3" opacity="0.3"/>
    <text x="430" y="307" font-size="9" text-anchor="middle">diy-stream-deck</text>

    <rect x="490" y="280" width="100" height="45" fill="#10b981" rx="3" opacity="0.3"/>
    <text x="540" y="307" font-size="9" text-anchor="middle">satisfactory-calc</text>

    <!-- Row 2 -->
    <rect x="50" y="340" width="100" height="45" fill="#10b981" rx="3" opacity="0.3"/>
    <text x="100" y="367" font-size="9" text-anchor="middle">genealogy-val</text>

    <rect x="160" y="340" width="100" height="45" fill="#10b981" rx="3" opacity="0.3"/>
    <text x="210" y="367" font-size="9" text-anchor="middle">linkendin-resume</text>

    <rect x="270" y="340" width="100" height="45" fill="#10b981" rx="3" opacity="0.3"/>
    <text x="320" y="367" font-size="9" text-anchor="middle">PO-GO-DEX</text>

    <rect x="380" y="340" width="100" height="45" fill="#10b981" rx="3" opacity="0.3"/>
    <text x="430" y="367" font-size="9" text-anchor="middle">server</text>

    <rect x="490" y="340" width="100" height="45" fill="#10b981" rx="3" opacity="0.3"/>
    <text x="540" y="367" font-size="9" text-anchor="middle">+2 more...</text>
  </g>

  <!-- Legend -->
  <g id="legend">
    <text x="50" y="450" font-size="11" font-weight="bold">Legend:</text>
    <rect x="50" y="460" width="15" height="15" fill="#7c3aed" opacity="0.3"/>
    <text x="70" y="472" font-size="10">Foundation (3)</text>

    <rect x="250" y="460" width="15" height="15" fill="#8b5cf6" opacity="0.3"/>
    <text x="270" y="472" font-size="10">Shared Libs (5)</text>

    <rect x="450" y="460" width="15" height="15" fill="#3b82f6" opacity="0.3"/>
    <text x="470" y="472" font-size="10">Backends (4)</text>

    <rect x="650" y="460" width="15" height="15" fill="#10b981" opacity="0.3"/>
    <text x="670" y="472" font-size="10">Products (12)</text>
  </g>
</svg>
```

---

## Game Development Configuration (Blender + Unity)

### Blender Integration
```
Task: 3D Asset Generation from AI
- Input: Game asset specification (JSON)
- Claude generates Blender Python script
- Scripts handle:
  * Mesh generation
  * Material setup
  * UV mapping
  * Rigging
  * Animation
- Output: .blend files exported as FBX/GLTF

Recommended Model: Sonnet
- Load: game-dev-CLAUDE.md + asset-spec.json
- Task: Generate Blender Python with bpy module calls
```

### Unity Integration
```
Task: Game Logic & System Generation
- Input: Game system specification (JSON)
- Claude generates C# code
- Scripts handle:
  * MonoBehaviour classes
  * Physics components
  * UI systems
  * Networking (if multiplayer)
  * Serialization

Recommended Model: Sonnet (standard) to Opus (complex multiplayer)
- Load: game-dev-CLAUDE.md + unity-setup.json
- Task: Generate production C# with proper Unity patterns
```

---

## Dev-Nexus Conflict Detection

### Local vs PR Detection
```python
# Detect conflicts between local changes and open PRs

rules:
  1. File-level conflict detection
     - Local files vs PR modified files
     - Alert if overlap > 30%

  2. Branch-level conflict detection
     - Check merge conflicts with base branch
     - List conflicting PRs

  3. Dependency conflict detection
     - If local changes touch shared libs
     - Alert all dependent projects

  4. CI status blocking
     - Block merge if local state conflicts with PR
     - Suggest rebase or squash
```

---

## New Notion Page Hierarchy

```
🏠 Chrysa Development Hub (MAIN)
├── 📊 Claude Optimization Guide
│   ├── Cost Analysis by Model
│   ├── Task-to-Model Routing Matrix
│   ├── Context Optimization Rules
│   └── Game Dev Special Cases (Blender/Unity)
├── 🏗️ Ecosystem Architecture
│   ├── Macro Dependency Graph (SVG)
│   ├── Micro Projects Graph (SVG)
│   ├── Service Topology (SVG)
│   └── Integration Points
├── 🎮 Game Development Config
│   ├── Blender Integration
│   ├── Unity Integration
│   ├── game-dev-CLAUDE.md
│   └── Asset Pipeline
├── 🔍 Dev-Nexus Conflict Detection
│   ├── Conflict Rules
│   ├── Auto-Detection System
│   └── Resolution Strategies
├── 📋 Project Structure Standards
│   ├── CLAUDE.md Template
│   ├── routes.md Format
│   ├── schema.md Layout
│   └── architecture.md Guidelines
└── ✅ Workflows & Checklists
    ├── Feature Dev Workflow
    ├── Bug Fix Workflow
    ├── Code Review Checklist
    └── Pre-Commit Validation
```
