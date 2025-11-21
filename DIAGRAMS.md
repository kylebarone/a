# ASCII Diagrams - Experiment v3 Architecture

Visual guide to how everything works in the experiment framework.

---

## Table of Contents
1. [System Overview](#system-overview)
2. [Experiment Run Flow](#experiment-run-flow)
3. [State Evolution](#state-evolution)
4. [Storage Architecture](#storage-architecture)
5. [Config to Pipeline Mapping](#config-to-pipeline-mapping)
6. [Question Generation Detail](#question-generation-detail)
7. [Genie Processing Detail](#genie-processing-detail)
8. [Result Aggregation](#result-aggregation)

---

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      EXPERIMENT FRAMEWORK                        │
└─────────────────────────────────────────────────────────────────┘

                    USER INPUT
                        │
                        ▼
        ┌───────────────────────────────┐
        │   run_experiment.py (CLI)     │
        │   - Parse args                │
        │   - Select configs            │
        │   - Create run_id             │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │   pipeline.py                 │
        │   - Build initial_state       │
        │   - Create agent pipeline     │
        │   - Execute via ADK Runner    │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────────────────┐
        │         SEQUENTIAL PIPELINE               │
        │  ┌─────────────────────────────────────┐  │
        │  │  1. Context Builder (BaseAgent)     │  │
        │  │     - Load SML, persona, etc.       │  │
        │  │     - Create ContextPacket          │  │
        │  └──────────────┬──────────────────────┘  │
        │                 │                          │
        │  ┌──────────────▼──────────────────────┐  │
        │  │  2. Generator (Agent + LLM)         │  │
        │  │     - Render Jinja2 template        │  │
        │  │     - Call Gemini                   │  │
        │  │     - Parse QuestionPlan            │  │
        │  └──────────────┬──────────────────────┘  │
        │                 │                          │
        │  ┌──────────────▼──────────────────────┐  │
        │  │  3. Mock Genie (BaseAgent)          │  │
        │  │     - Process each question         │  │
        │  │     - Generate mock results         │  │
        │  │     - Create GenieResults           │  │
        │  └──────────────┬──────────────────────┘  │
        └─────────────────┼───────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │   ADK Session Service            │
        │   (DatabaseSessionService)       │
        │   - Save state to SQLite         │
        │   - Save events to SQLite        │
        │   - Link by session_id           │
        └─────────────────┬───────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │   experiments.db (SQLite)        │
        │   ┌───────────────────────────┐  │
        │   │ sessions table            │  │
        │   │ - id (session_id)         │  │
        │   │ - state (JSON)            │  │
        │   │ - events (JSON)           │  │
        │   │ - created_at              │  │
        │   └───────────────────────────┘  │
        └─────────────────┬───────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │   export_to_excel.py             │
        │   - Query sessions by run_id     │
        │   - Aggregate results            │
        │   - Export to Excel              │
        └─────────────────┬───────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │   data/outputs/                  │
        │   - experiment_<run_id>.xlsx     │
        │   - results_<run_id>.json        │
        └─────────────────────────────────┘
```

---

## Experiment Run Flow

### Single Question, Single Config

```
USER RUNS:
  python scripts/run_experiment.py "Why is margin down?" --configs baseline

┌─────────────────────────────────────────────────────────────────┐
│ STEP 1: Initialization                                          │
└─────────────────────────────────────────────────────────────────┘

  run_experiment.py
      │
      ├──> Create run_id = "20241122_093045"
      │
      ├──> Load config = GeneratorConfig(name="baseline", ...)
      │
      └──> Build initial_state:
              {
                "seed_question": "Why is margin down?",
                "run_id": "20241122_093045",
                "config_name": "baseline",
                "context_config": {
                  "sml_grounding": False,
                  "persona_info": False,
                  "pattern_library": False,
                  "few_shot_examples": False
                },
                "generator_type": "baseline",
                "num_questions": 5
              }

┌─────────────────────────────────────────────────────────────────┐
│ STEP 2: Pipeline Creation                                       │
└─────────────────────────────────────────────────────────────────┘

  pipeline.py::run_experiment()
      │
      ├──> Check context_config
      │    ├──> No context enabled
      │    └──> Skip ContextBuilderAgent
      │
      ├──> Create sub_agents = [
      │        create_generator_agent("baseline", "gemini-2.0-flash-exp"),
      │        MockGenieAgent()
      │    ]
      │
      └──> pipeline = SequentialAgent(
               name="pipeline_baseline",
               sub_agents=sub_agents
           )

┌─────────────────────────────────────────────────────────────────┐
│ STEP 3: ADK Runner Execution                                    │
└─────────────────────────────────────────────────────────────────┘

  session_id = "20241122_093045_baseline_a3f2b1c9"

  runner = Runner(
      app_name="question_experiment",
      agent=pipeline,
      session_service=DatabaseSessionService("sqlite:///experiments.db")
  )

  runner.run_async(
      user_id="experiment",
      session_id=session_id,
      new_message="Why is margin down?",
      initial_state=initial_state  ← Injected here!
  )

      │
      ▼
  ┌──────────────────────────────────────────────────┐
  │ ADK Creates Session                              │
  │ - Loads/creates session_id                       │
  │ - Sets session.state = initial_state             │
  │ - Prepares context for agents                    │
  └──────────────────┬───────────────────────────────┘
                     │
                     ▼
  ┌──────────────────────────────────────────────────┐
  │ Agent 1: Generator (Skip Context Builder)       │
  │                                                  │
  │ Input from state:                                │
  │   - seed_question                                │
  │   - num_questions                                │
  │   - (no context_packet - baseline)               │
  │                                                  │
  │ Process:                                         │
  │   1. Render Jinja2 template (no context)        │
  │   2. Call LLM (Gemini)                          │
  │   3. Parse JSON response                        │
  │                                                  │
  │ Output event:                                    │
  │   Event(                                         │
  │     author="baseline",                           │
  │     actions=EventActions(                        │
  │       state_delta={                              │
  │         "question_plan": {                       │
  │           "anchor_question": "...",              │
  │           "questions": [...]                     │
  │         }                                        │
  │       }                                          │
  │     )                                            │
  │   )                                              │
  └──────────────────┬───────────────────────────────┘
                     │
                     ▼ (ADK updates state)
  ┌──────────────────────────────────────────────────┐
  │ session.state now includes:                      │
  │   - seed_question                                │
  │   - run_id, config_name                          │
  │   - question_plan ← NEW!                         │
  └──────────────────┬───────────────────────────────┘
                     │
                     ▼
  ┌──────────────────────────────────────────────────┐
  │ Agent 2: MockGenieAgent                          │
  │                                                  │
  │ Input from state:                                │
  │   - question_plan                                │
  │                                                  │
  │ Process:                                         │
  │   For each question in plan:                     │
  │     1. Generate mock steps (2-4 steps)          │
  │     2. Create GenieResult                       │
  │                                                  │
  │ Output event:                                    │
  │   Event(                                         │
  │     author="mock_genie",                         │
  │     actions=EventActions(                        │
  │       state_delta={                              │
  │         "genie_results": [...]                   │
  │       }                                          │
  │     )                                            │
  │   )                                              │
  └──────────────────┬───────────────────────────────┘
                     │
                     ▼ (ADK updates state)
  ┌──────────────────────────────────────────────────┐
  │ FINAL session.state:                             │
  │   {                                              │
  │     "seed_question": "Why is margin down?",      │
  │     "run_id": "20241122_093045",                 │
  │     "config_name": "baseline",                   │
  │     "generator_type": "baseline",                │
  │     "question_plan": {...},                      │
  │     "genie_results": [{...}, {...}, ...]         │
  │   }                                              │
  └──────────────────┬───────────────────────────────┘
                     │
                     ▼
  ┌──────────────────────────────────────────────────┐
  │ ADK Persists to Database                         │
  │                                                  │
  │ INSERT INTO sessions VALUES (                    │
  │   id = "20241122_093045_baseline_a3f2b1c9",     │
  │   app_name = "question_experiment",              │
  │   user_id = "experiment",                        │
  │   state = '{"seed_question": ...}',  ← JSON     │
  │   events = '[{...}, {...}]',         ← JSON     │
  │   created_at = "2024-11-22T09:30:45"             │
  │ )                                                │
  └──────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ STEP 4: Result Tracking                                         │
└─────────────────────────────────────────────────────────────────┘

  ExperimentResults.add_result(
      seed_question="Why is margin down?",
      config_name="baseline",
      session_id="20241122_093045_baseline_a3f2b1c9",
      state=ExperimentState(...),
      success=True
  )

      │
      ▼
  Save to: data/outputs/results_20241122_093045.json
  {
    "run_id": "20241122_093045",
    "total_runs": 1,
    "successful": 1,
    "results": [...]
  }
```

### All Seeds, All Configs (Full Experiment)

```
USER RUNS:
  python scripts/run_experiment.py --all-seeds

┌─────────────────────────────────────────────────────────────────┐
│ Outer Loop: Seeds (5 seeds)                                     │
└─────────────────────────────────────────────────────────────────┘

For each seed in test_seeds.json:

  Seed 1: "Why is margin for Category X down?"
    │
    ├──> run_id = "20241122_093045_seed1"
    │
    └──> Inner Loop: Configs (5 configs)
            │
            ├──> Run: baseline
            │    └──> session_id = "20241122_093045_seed1_baseline_abc123"
            │         └──> Stored in DB
            │
            ├──> Run: with_sml
            │    └──> session_id = "20241122_093045_seed1_with_sml_def456"
            │         └──> Stored in DB
            │
            ├──> Run: with_sml_persona
            │    └──> session_id = "20241122_093045_seed1_with_sml_persona_ghi789"
            │         └──> Stored in DB
            │
            ├──> Run: with_sml_persona_patterns
            │    └──> session_id = "..."
            │         └──> Stored in DB
            │
            └──> Run: full_context
                 └──> session_id = "..."
                      └──> Stored in DB

  Seed 2: "How did GMV perform this quarter?"
    └──> ... (5 more sessions)

  ... (Seeds 3, 4, 5)

TOTAL: 5 seeds × 5 configs = 25 sessions in experiments.db
```

---

## State Evolution

```
┌─────────────────────────────────────────────────────────────────┐
│ INITIAL STATE (Before Pipeline)                                 │
└─────────────────────────────────────────────────────────────────┘

session.state = {
  "seed_question": "Why is margin down?",
  "run_id": "20241122_093045",
  "config_name": "full_context",
  "context_config": {...},
  "generator_type": "context",
  "num_questions": 5
}

        │ AGENT 1: ContextBuilderAgent
        ▼

┌─────────────────────────────────────────────────────────────────┐
│ AFTER CONTEXT BUILDER                                           │
└─────────────────────────────────────────────────────────────────┘

session.state = {
  ...above,
  "context_packet": {  ← ADDED!
    "sml": {...},
    "persona": {...},
    "patterns": [...],
    "examples": [...],
    "built_at": "...",
    "builder_type": "simple"
  }
}

        │ AGENT 2: Generator
        ▼

┌─────────────────────────────────────────────────────────────────┐
│ AFTER GENERATOR                                                 │
└─────────────────────────────────────────────────────────────────┘

session.state = {
  ...above,
  "question_plan": {  ← ADDED!
    "anchor_question": "...",
    "questions": [...],
    "metadata": {...}
  }
}

        │ AGENT 3: MockGenie
        ▼

┌─────────────────────────────────────────────────────────────────┐
│ AFTER MOCK GENIE (FINAL)                                        │
└─────────────────────────────────────────────────────────────────┘

session.state = {
  ...above,
  "genie_results": [  ← ADDED!
    {
      "question_text": "...",
      "session_id": "genie_abc",
      "steps": [...],
      "status": "success"
    },
    ...
  ]
}

        │ ADK PERSISTS
        ▼

experiments.db (Full state + events)
```

---

## Storage Architecture

### Database Schema

```
experiments.db
│
├── TABLE: sessions
│   │
│   ├── Columns:
│   │   ├── id (TEXT, PRIMARY KEY)          "20241122_093045_baseline_abc"
│   │   ├── app_name (TEXT)                 "question_experiment"
│   │   ├── user_id (TEXT)                  "experiment"
│   │   ├── state (TEXT)                    JSON blob {"seed_question": ...}
│   │   ├── events (TEXT)                   JSON array [{...}, {...}]
│   │   ├── created_at (TIMESTAMP)
│   │   └── updated_at (TIMESTAMP)
│   │
│   └── Example Row:
│       {
│         "id": "20241122_093045_baseline_abc123",
│         "state": '{"seed_question": "Why is margin down?", ...}',
│         "events": '[{author: "baseline", ...}, ...]'
│       }
│
└── Indexes:
    ├── PRIMARY KEY on id
    ├── INDEX on (app_name, user_id)
    └── INDEX on created_at
```

### Query Examples

```sql
-- Get single session
SELECT * FROM sessions
WHERE id = '20241122_093045_baseline_abc123';

-- Get all sessions for run
SELECT * FROM sessions
WHERE id LIKE '20241122_093045%'
ORDER BY created_at;

-- Extract config from JSON
SELECT 
  id,
  json_extract(state, '$.config_name') as config,
  json_extract(state, '$.generator_type') as type
FROM sessions
WHERE id LIKE '20241122_093045%';
```

---

## Config to Pipeline Mapping

```
┌─────────────────────────────────────────────────────────────────┐
│ CONFIG: baseline                                                │
└─────────────────────────────────────────────────────────────────┘

GeneratorConfig(
  name="baseline",
  context_config=ContextConfig(
    sml_grounding=False,      ← All False
    persona_info=False,
    pattern_library=False,
    few_shot_examples=False
  )
)

        │
        ▼

has_context = False  (all flags are False)

        │
        ▼

Pipeline = SequentialAgent([
  # ContextBuilderAgent SKIPPED
  create_generator_agent("baseline"),
  MockGenieAgent()
])

═══════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────┐
│ CONFIG: full_context                                            │
└─────────────────────────────────────────────────────────────────┘

GeneratorConfig(
  name="full_context",
  context_config=ContextConfig(
    sml_grounding=True,       ← All True
    persona_info=True,
    pattern_library=True,
    few_shot_examples=True
  )
)

        │
        ▼

has_context = True  (at least one flag is True)

        │
        ▼

Pipeline = SequentialAgent([
  ContextBuilderAgent(),              ← ADDED!
  create_generator_agent("full_context"),
  MockGenieAgent()
])
```

---

## Question Generation Detail

```
┌─────────────────────────────────────────────────────────────────┐
│ INPUT: session.state                                            │
└─────────────────────────────────────────────────────────────────┘

{
  "seed_question": "Why is margin down?",
  "num_questions": 5,
  "context_packet": {
    "sml": {...},
    "persona": {...}
  }
}

        │
        ▼

┌─────────────────────────────────────────────────────────────────┐
│ STEP 1: ADK Renders Jinja2 Template                            │
└─────────────────────────────────────────────────────────────────┘

Template:
"""
Generate {{ num_questions }} questions.

{% if context_packet.persona %}
User: {{ context_packet.persona.name }}
{% endif %}

Question: {{ seed_question }}
"""

Rendered:
"""
Generate 5 questions.

User: Merchandising Finance Analyst

Question: Why is margin down?
"""

        │
        ▼

┌─────────────────────────────────────────────────────────────────┐
│ STEP 2: Call LLM (Gemini)                                      │
└─────────────────────────────────────────────────────────────────┘

POST to Gemini API with rendered prompt

        │
        ▼

LLM Response:
```json
{
  "anchor_question": "Why is margin down?",
  "questions": [
    {"text": "Show margin trend", ...},
    {"text": "Break down by category", ...},
    ...
  ]
}
```

        │
        ▼

┌─────────────────────────────────────────────────────────────────┐
│ STEP 3: Validate with Pydantic                                 │
└─────────────────────────────────────────────────────────────────┘

plan = QuestionPlan(**json.loads(response))

        │
        ▼

┌─────────────────────────────────────────────────────────────────┐
│ STEP 4: Update State                                           │
└─────────────────────────────────────────────────────────────────┘

Event(
  actions=EventActions(
    state_delta={"question_plan": plan.model_dump()}
  )
)

ADK: session.state["question_plan"] = {...}
```

---

## Genie Processing Detail

```
┌─────────────────────────────────────────────────────────────────┐
│ INPUT: session.state["question_plan"]                          │
└─────────────────────────────────────────────────────────────────┘

{
  "questions": [
    {"text": "Q1", ...},
    {"text": "Q2", ...},
    {"text": "Q3", ...},
    {"text": "Q4", ...},
    {"text": "Q5", ...}
  ]
}

        │
        ▼

┌─────────────────────────────────────────────────────────────────┐
│ LOOP: Process Each Question                                     │
└─────────────────────────────────────────────────────────────────┘

For question_idx, question in enumerate(questions):

  ┌─────────────────────────────────────────────────────────────┐
  │ Question 1: "Show margin trend"                             │
  └─────────────────────────────────────────────────────────────┘
  
  1. Generate mock steps (random 2-4)
     
     Step 1: "parse" → 120ms
     Step 2: "retrieve" → 250ms
     Step 3: "analyze" → 380ms
  
  2. Create GenieResult
     
     GenieResult(
       question_text="Show margin trend",
       session_id="genie_abc123",
       steps=[step1, step2, step3],
       total_duration_ms=750,
       status="success"
     )
  
  3. Add to results list

  ... (Repeat for Q2, Q3, Q4, Q5)

        │
        ▼

┌─────────────────────────────────────────────────────────────────┐
│ OUTPUT: All GenieResults                                        │
└─────────────────────────────────────────────────────────────────┘

genie_results = [
  GenieResult(question_text="Q1", ...),
  GenieResult(question_text="Q2", ...),
  GenieResult(question_text="Q3", ...),
  GenieResult(question_text="Q4", ...),
  GenieResult(question_text="Q5", ...)
]

        │
        ▼

┌─────────────────────────────────────────────────────────────────┐
│ UPDATE STATE                                                    │
└─────────────────────────────────────────────────────────────────┘

Event(
  actions=EventActions(
    state_delta={"genie_results": [r.model_dump() for r in results]}
  )
)

ADK: session.state["genie_results"] = [...]
```

---

## Result Aggregation

```
┌─────────────────────────────────────────────────────────────────┐
│ STEP 1: Load Sessions from DB                                  │
└─────────────────────────────────────────────────────────────────┘

Query: SELECT * FROM sessions WHERE id LIKE '20241122_093045%'

Result: 25 sessions (5 seeds × 5 configs)

        │
        ▼

┌─────────────────────────────────────────────────────────────────┐
│ STEP 2: Parse Each Session                                     │
└─────────────────────────────────────────────────────────────────┘

For each session:
  - state → ExperimentState
  - state.question_plan → QuestionPlan
  - state.genie_results → List[GenieResult]

        │
        ▼

┌─────────────────────────────────────────────────────────────────┐
│ STEP 3: Create Flat Rows                                       │
└─────────────────────────────────────────────────────────────────┘

For each session:
  For each question in plan.questions:
    
    row = {
      "run_id": state.run_id,
      "config_name": state.config_name,
      "seed_question": state.seed_question,
      "question_text": question.text,
      "genie_session_id": genie_result.session_id,
      "genie_status": genie_result.status,
      "has_sml": state.context_config.sml_grounding,
      ...
    }

Result: 125 rows (25 sessions × 5 questions)

        │
        ▼

┌─────────────────────────────────────────────────────────────────┐
│ STEP 4: Write to Excel                                         │
└─────────────────────────────────────────────────────────────────┘

Excel File:
┌────────────┬──────────┬───────────┬──────────────┬─────┐
│ run_id     │ config   │ seed      │ question     │ ... │
├────────────┼──────────┼───────────┼──────────────┼─────┤
│ 20241122.. │ baseline │ Why mar.. │ Show trend   │ ... │
│ 20241122.. │ baseline │ Why mar.. │ Break down   │ ... │
│ 20241122.. │ with_sml │ Why mar.. │ Show trend   │ ... │
│ ...        │ ...      │ ...       │ ...          │ ... │
└────────────┴──────────┴───────────┴──────────────┴─────┘

Features:
  ✓ Formatted headers (blue, bold, white text)
  ✓ Auto-sized columns
  ✓ Frozen header row
  ✓ One row per question
  ✓ Full traceability
```

---

## Summary: Complete Data Flow

```
┌────────────┐
│ User Input │
└──────┬─────┘
       │
       ▼
┌──────────────┐
│ Create State │  → Dict with config + seed
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│ ADK Runner       │  → session.state = initial_state
└──────┬───────────┘
       │
       ▼
┌──────────────────────────┐
│ Pipeline Executes        │
│                          │
│ Agent 1 → Event(delta)   │ → state updated
│ Agent 2 → Event(delta)   │ → state updated
│ Agent 3 → Event(delta)   │ → state updated (final)
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────┐
│ ADK Persists         │  → SQLite (state + events as JSON)
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ experiments.db       │  → Queryable, recoverable
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Export Script        │  → Loads, aggregates, formats
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Excel File           │  → Analysis-ready results
└──────────────────────┘
```

---

**That's everything!** Complete visual guide to all data flows. 🎯
