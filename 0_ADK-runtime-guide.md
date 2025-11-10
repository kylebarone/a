# ADK Runtime & Services: Complete Guide with Code Examples

## Table of Contents
1. [Runner and Event Loop](#runner-and-event-loop)
2. [Session Services](#session-services)
3. [Artifact Services](#artifact-services)
4. [Events and State](#events-and-state)
5. [Core Building Blocks](#core-building-blocks)
6. [Complete Working Examples](#complete-working-examples)

---

## 1. Runner and Event Loop

### Overview
The **Runner** is the central orchestration engine that manages the event loop between user input, agent execution, and backend services.

### Key Responsibilities
- **Session Management**: Load/create sessions, retrieve history
- **Agent Invocation**: Call agent's `run_async` method
- **Context Creation**: Bundle session info, services, user input into `InvocationContext`
- **Event Streaming**: Process events yielded by agents in real-time
- **Input Handling**: Record user messages, handle binary blobs

### Basic Runner Setup

```python
from google.adk import Runner
from google.adk.services import (
    InMemorySessionService,
    InMemoryArtifactService,
    InMemoryMemoryService
)
from google.adk.agents import Agent

# Initialize services
session_service = InMemorySessionService()
artifact_service = InMemoryArtifactService()
memory_service = InMemoryMemoryService()

# Create your root agent
my_agent = Agent(
    name="MyAssistant",
    model="gemini-2.0-flash-exp",
    instruction="You are a helpful assistant."
)

# Initialize Runner
runner = Runner(
    app_name="my_app",
    agent=my_agent,
    session_service=session_service,
    artifact_service=artifact_service,
    memory_service=memory_service
)
```

### Running the Event Loop

```python
import asyncio

async def run_agent_interaction():
    user_id = "user_123"
    session_id = "session_abc"
    
    # Run agent and stream events
    async for event in runner.run_async(
        user_id=user_id,
        session_id=session_id,
        new_message="What's the weather in Paris?"
    ):
        # Process each event as it comes
        print(f"Event from {event.author}: {event.content}")
        
        # Check for specific event types
        if event.actions and event.actions.state_delta:
            print(f"State updated: {event.actions.state_delta}")

# Run
asyncio.run(run_agent_interaction())
```

### Runner with RunConfig

```python
from google.adk.runtime import RunConfig

# Configure runtime behavior
config = RunConfig(
    streaming=True,  # Enable streaming responses
    save_input_blobs_as_artifacts=True,  # Auto-save uploaded files
    max_llm_calls=10  # Limit LLM calls per turn
)

async for event in runner.run_async(
    user_id=user_id,
    session_id=session_id,
    new_message="Hello!",
    config=config
):
    if event.partial:
        # Handle streaming chunk
        print(f"Partial: {event.content}", end="", flush=True)
    else:
        # Final complete event
        print(f"\nComplete: {event.content}")
```

---

## 2. Session Services

### Overview
**SessionService** manages conversation sessions, including event history and state persistence.

### Available Implementations

#### InMemorySessionService
```python
from google.adk.services import InMemorySessionService

# Fast, volatile, good for development
session_service = InMemorySessionService()
```

#### DatabaseSessionService
```python
from google.adk.services import DatabaseSessionService

# Persistent, survives restarts
session_service = DatabaseSessionService(
    connection_string="postgresql://user:pass@localhost/db"
    # Or: "mysql://...", "sqlite:///local.db"
)
```

#### VertexAiSessionService
```python
from google.adk.services import VertexAiSessionService

# Cloud-based, for production on GCP
session_service = VertexAiSessionService(
    project_id="my-project",
    location="us-central1",
    reasoning_engine_id="my-engine-id"
)
```

### Working with Sessions

```python
async def session_operations():
    # Create a new session
    session = await session_service.create_session(
        app_name="my_app",
        user_id="user_123",
        initial_state={"user_name": "Alice", "preferences": {}}
    )
    
    print(f"Session ID: {session.id}")
    print(f"Initial state: {session.state}")
    
    # List all sessions for a user
    sessions = await session_service.list_sessions(
        app_name="my_app",
        user_id="user_123"
    )
    
    for s in sessions:
        print(f"Session {s.id}: {len(s.events)} events")
    
    # Retrieve existing session
    existing_session = await session_service.get_session(
        app_name="my_app",
        user_id="user_123",
        session_id=session.id
    )
    
    # Delete session
    await session_service.delete_session(
        app_name="my_app",
        user_id="user_123",
        session_id=session.id
    )
```

### Session Lifecycle Pattern

```python
async def multi_turn_conversation():
    """Pattern for persistent multi-turn conversations"""
    
    user_id = "user_123"
    session_id = None  # Will be auto-generated on first turn
    
    # Turn 1
    print("=== Turn 1 ===")
    async for event in runner.run_async(
        user_id=user_id,
        session_id=session_id,
        new_message="My name is Alice"
    ):
        if not session_id and hasattr(event, 'session_id'):
            session_id = event.session_id
        print(event.content)
    
    # Turn 2 - Session continues with memory
    print("\n=== Turn 2 ===")
    async for event in runner.run_async(
        user_id=user_id,
        session_id=session_id,  # Same session
        new_message="What's my name?"
    ):
        print(event.content)
```

---

## 3. Artifact Services

### Overview
**ArtifactService** handles large binary/non-text data (images, PDFs, audio) separate from the event stream.

### Available Implementations

#### InMemoryArtifactService
```python
from google.adk.services import InMemoryArtifactService

# Volatile, for testing
artifact_service = InMemoryArtifactService()
```

#### GcsArtifactService
```python
from google.adk.services import GcsArtifactService

# Cloud storage, scalable
artifact_service = GcsArtifactService(
    bucket_name="my-artifacts-bucket"
)
```

### Working with Artifacts

```python
async def artifact_operations():
    # Save an artifact
    with open("image.png", "rb") as f:
        image_data = f.read()
    
    artifact_id = await artifact_service.save_artifact(
        app_name="my_app",
        user_id="user_123",
        session_id="session_abc",
        filename="user_upload.png",
        content=image_data,
        mime_type="image/png"
    )
    
    print(f"Saved artifact: {artifact_id}")
    
    # Load an artifact
    content, metadata = await artifact_service.load_artifact(
        app_name="my_app",
        user_id="user_123",
        session_id="session_abc",
        filename="user_upload.png"
    )
    
    print(f"Loaded {len(content)} bytes")
    print(f"MIME type: {metadata.get('mime_type')}")
    
    # List artifacts for a session
    artifacts = await artifact_service.list_artifacts(
        app_name="my_app",
        user_id="user_123",
        session_id="session_abc"
    )
    
    for artifact in artifacts:
        print(f"- {artifact.filename} ({artifact.size} bytes)")
```

### Artifacts in Agent Workflow

```python
from google.adk.agents import Agent

# Agent that processes uploaded images
image_agent = Agent(
    name="ImageAnalyzer",
    model="gemini-2.0-flash-exp",
    instruction="""
    You can analyze images. When a user uploads an image,
    describe what you see in detail.
    """
)

async def handle_image_upload():
    # User uploads image
    with open("photo.jpg", "rb") as f:
        image_bytes = f.read()
    
    # Runner auto-saves if configured
    config = RunConfig(save_input_blobs_as_artifacts=True)
    
    async for event in runner.run_async(
        user_id="user_123",
        session_id="session_abc",
        new_message="What's in this image?",
        attachments=[{
            "data": image_bytes,
            "mime_type": "image/jpeg",
            "filename": "photo.jpg"
        }],
        config=config
    ):
        # Event will reference artifact, not contain raw bytes
        print(event.content)
```

---

## 4. Events and State

### Event Structure

```python
class Event:
    id: str                    # Unique event ID
    author: str               # "user", "MyAgent", "ToolName"
    content: Content          # Text, function call, or result
    timestamp: datetime
    actions: EventActions     # Side effects (state, artifacts, control)
    partial: bool            # True for streaming chunks
    branch: str              # Hierarchical branch identifier
```

### Event Types

#### 1. User Message Event
```python
# Created by Runner when user sends input
{
    "author": "user",
    "content": {"parts": [{"text": "Hello!"}]},
    "actions": {}
}
```

#### 2. Agent Response Event
```python
# Agent's text response
{
    "author": "MyAgent",
    "content": {"parts": [{"text": "Hi there!"}]},
    "actions": {}
}
```

#### 3. Function Call Event
```python
# Agent requests tool execution
{
    "author": "MyAgent",
    "content": {
        "parts": [{
            "function_call": {
                "name": "get_weather",
                "args": {"city": "Paris"}
            }
        }]
    },
    "actions": {}
}
```

#### 4. Function Result Event
```python
# Tool execution result
{
    "author": "get_weather",
    "content": {
        "parts": [{
            "function_response": {
                "name": "get_weather",
                "response": {"temp": "15C", "conditions": "Cloudy"}
            }
        }]
    },
    "actions": {
        "state_delta": {"latest_weather": "15C, Cloudy"}
    }
}
```

### Working with State

```python
async def state_management_example():
    """How to read and write session state"""
    
    from google.adk.agents import BaseAgent
    from google.adk.context import InvocationContext
    from typing import AsyncGenerator
    
    class StatefulAgent(BaseAgent):
        async def _run_async_impl(
            self, 
            ctx: InvocationContext
        ) -> AsyncGenerator[Event, None]:
            
            # READ state
            counter = ctx.session.state.get("counter", 0)
            user_name = ctx.session.state.get("user_name", "stranger")
            
            print(f"Counter: {counter}, User: {user_name}")
            
            # WRITE state via event
            new_counter = counter + 1
            
            # Create event with state update
            event = Event(
                author=self.name,
                content={"parts": [{"text": f"Hello {user_name}! Count: {new_counter}"}]},
                actions=EventActions(
                    state_delta={
                        "counter": new_counter,
                        "last_interaction": datetime.now().isoformat()
                    }
                )
            )
            
            yield event
```

### State Delta Pattern

```python
# State changes are ADDITIVE via state_delta
current_state = {"a": 1, "b": 2}

# Apply state_delta
state_delta = {"b": 3, "c": 4}

# Result: {"a": 1, "b": 3, "c": 4}
# (b updated, c added, a unchanged)
```

### Temporary State

```python
# Keys prefixed with "temp:" are NOT persisted
event_actions = EventActions(
    state_delta={
        "temp:working_data": "...",  # Discarded after invocation
        "final_result": "..."        # Persisted
    }
)
```

---

## 5. Core Building Blocks

### LLM Agent with Tools

```python
from google.adk.agents import Agent
from google.adk.tools import FunctionTool

# Define custom tool
def calculate_sum(a: int, b: int) -> int:
    """Add two numbers together"""
    return a + b

def search_database(query: str) -> str:
    """Search internal database"""
    # Your implementation
    return f"Results for: {query}"

# Create tools
sum_tool = FunctionTool(calculate_sum)
search_tool = FunctionTool(search_database)

# Agent with tools
agent = Agent(
    name="Assistant",
    model="gemini-2.0-flash-exp",
    instruction="""
    You are a helpful assistant with access to:
    - calculate_sum: for math operations
    - search_database: for looking up information
    
    Use these tools when appropriate.
    """,
    tools=[sum_tool, search_tool]
)
```

### Sequential Agent

```python
from google.adk.agents import SequentialAgent, Agent

# Define sub-agents
step1 = Agent(
    name="Extractor",
    instruction="Extract key information from the user's request.",
    output_key="extracted_info"  # Stores result here
)

step2 = Agent(
    name="Analyzer",
    instruction="Analyze the extracted information: {extracted_info}",
    output_key="analysis"
)

step3 = Agent(
    name="Reporter",
    instruction="Create a report based on: {analysis}"
)

# Sequential workflow
workflow = SequentialAgent(
    name="AnalysisWorkflow",
    sub_agents=[step1, step2, step3]
)
```

### Parallel Agent

```python
from google.adk.agents import ParallelAgent, Agent

# Create parallel researchers
researcher1 = Agent(
    name="TopicA_Researcher",
    instruction="Research topic A and summarize findings.",
    output_key="topic_a_summary"
)

researcher2 = Agent(
    name="TopicB_Researcher",
    instruction="Research topic B and summarize findings.",
    output_key="topic_b_summary"
)

researcher3 = Agent(
    name="TopicC_Researcher",
    instruction="Research topic C and summarize findings.",
    output_key="topic_c_summary"
)

# Parallel execution
parallel_research = ParallelAgent(
    name="ParallelResearch",
    sub_agents=[researcher1, researcher2, researcher3]
)

# Synthesis agent to combine results
synthesizer = Agent(
    name="Synthesizer",
    instruction="""
    Combine the research from all topics:
    - Topic A: {topic_a_summary}
    - Topic B: {topic_b_summary}
    - Topic C: {topic_c_summary}
    
    Create a comprehensive report.
    """
)

# Complete workflow
workflow = SequentialAgent(
    name="ResearchPipeline",
    sub_agents=[parallel_research, synthesizer]
)
```

### Loop Agent

```python
from google.adk.agents import LoopAgent, Agent
from google.adk.tools import ExitLoopTool

# Agent that refines text
refiner = Agent(
    name="TextRefiner",
    instruction="""
    Refine the text. If it's good enough (clear, concise, well-structured),
    call the exit_loop tool. Otherwise, improve it and set state.
    """,
    tools=[ExitLoopTool()],
    output_key="refined_text"
)

# Quality checker
checker = Agent(
    name="QualityChecker",
    instruction="""
    Check if refined_text meets quality standards.
    Set state["quality_ok"] = True if good, False otherwise.
    """,
)

# Loop until quality is good
loop = LoopAgent(
    name="RefinementLoop",
    sub_agents=[refiner, checker],
    max_iterations=5
)
```

### Custom Agent

```python
from google.adk.agents import BaseAgent
from google.adk.context import InvocationContext
from google.adk.events import Event
from typing import AsyncGenerator

class ConditionalAgent(BaseAgent):
    """Agent with if-else logic"""
    
    def __init__(self, condition_agent, true_agent, false_agent):
        super().__init__(name="ConditionalAgent")
        self.condition_agent = condition_agent
        self.true_agent = true_agent
        self.false_agent = false_agent
    
    async def _run_async_impl(
        self, 
        ctx: InvocationContext
    ) -> AsyncGenerator[Event, None]:
        
        # Step 1: Run condition agent
        async for event in self.condition_agent.run_async(ctx):
            yield event
        
        # Step 2: Check condition in state
        condition_met = ctx.session.state.get("condition", False)
        
        # Step 3: Branch based on condition
        if condition_met:
            async for event in self.true_agent.run_async(ctx):
                yield event
        else:
            async for event in self.false_agent.run_async(ctx):
                yield event

# Usage
condition_checker = Agent(
    name="Checker",
    instruction="Check if user wants option A. Set state['condition'] = True if yes.",
    output_key="check_result"
)

option_a_agent = Agent(
    name="OptionA",
    instruction="Handle option A"
)

option_b_agent = Agent(
    name="OptionB",
    instruction="Handle option B"
)

conditional = ConditionalAgent(
    condition_agent=condition_checker,
    true_agent=option_a_agent,
    false_agent=option_b_agent
)
```

---

## 6. Complete Working Examples

### Example 1: Simple Chat Agent

```python
import asyncio
from google.adk import Runner
from google.adk.agents import Agent
from google.adk.services import InMemorySessionService

async def main():
    # Setup
    agent = Agent(
        name="ChatBot",
        model="gemini-2.0-flash-exp",
        instruction="You are a friendly chatbot."
    )
    
    runner = Runner(
        app_name="chat",
        agent=agent,
        session_service=InMemorySessionService()
    )
    
    # Chat loop
    user_id = "user_1"
    session_id = "session_1"
    
    while True:
        user_input = input("You: ")
        if user_input.lower() in ["exit", "quit"]:
            break
        
        print("Bot: ", end="", flush=True)
        async for event in runner.run_async(
            user_id=user_id,
            session_id=session_id,
            new_message=user_input
        ):
            if event.content and not event.partial:
                print(event.content)

asyncio.run(main())
```

### Example 2: Multi-Step Research Workflow

```python
from google.adk.agents import SequentialAgent, ParallelAgent, Agent
from google.adk.tools import FunctionTool

# Define tools
def web_search(query: str) -> str:
    """Search the web"""
    return f"Search results for: {query}"

search_tool = FunctionTool(web_search)

# Build workflow
query_parser = Agent(
    name="Parser",
    instruction="Extract research topics from user query. List 3 topics.",
    output_key="topics"
)

researcher_a = Agent(
    name="ResearcherA",
    instruction="Research first topic from: {topics}",
    tools=[search_tool],
    output_key="research_a"
)

researcher_b = Agent(
    name="ResearcherB",
    instruction="Research second topic from: {topics}",
    tools=[search_tool],
    output_key="research_b"
)

researcher_c = Agent(
    name="ResearcherC",
    instruction="Research third topic from: {topics}",
    tools=[search_tool],
    output_key="research_c"
)

parallel_research = ParallelAgent(
    name="ParallelResearch",
    sub_agents=[researcher_a, researcher_b, researcher_c]
)

synthesizer = Agent(
    name="Synthesizer",
    instruction="""
    Combine all research:
    - Research A: {research_a}
    - Research B: {research_b}
    - Research C: {research_c}
    
    Create comprehensive report.
    """
)

# Complete workflow
research_workflow = SequentialAgent(
    name="ResearchWorkflow",
    sub_agents=[query_parser, parallel_research, synthesizer]
)

# Run it
async def run_research():
    runner = Runner(
        app_name="research",
        agent=research_workflow,
        session_service=InMemorySessionService()
    )
    
    async for event in runner.run_async(
        user_id="researcher_1",
        session_id="research_session",
        new_message="Research AI safety, machine learning ethics, and alignment"
    ):
        print(f"[{event.author}]: {event.content}")

asyncio.run(run_research())
```

### Example 3: Stateful Multi-Turn Agent

```python
from google.adk.agents import Agent

# Agent that maintains conversation context
stateful_agent = Agent(
    name="StatefulAssistant",
    model="gemini-2.0-flash-exp",
    instruction="""
    You are a helpful assistant that remembers context.
    
    Current session state:
    - User name: {user_name}
    - Preference: {preference}
    - Conversation count: {conv_count}
    
    Update state as needed during conversation.
    """
)

async def stateful_conversation():
    runner = Runner(
        app_name="stateful",
        agent=stateful_agent,
        session_service=DatabaseSessionService("sqlite:///sessions.db")
    )
    
    user_id = "alice"
    session_id = "alice_session"
    
    # Turn 1
    async for event in runner.run_async(
        user_id=user_id,
        session_id=session_id,
        new_message="My name is Alice and I prefer Python",
        initial_state={"conv_count": 0}
    ):
        if not event.partial:
            print(event.content)
    
    # Turn 2 - agent remembers!
    async for event in runner.run_async(
        user_id=user_id,
        session_id=session_id,
        new_message="What's my name and preference?"
    ):
        if not event.partial:
            print(event.content)

asyncio.run(stateful_conversation())
```

---

## Key Takeaways

1. **Runner** orchestrates everything - it's your entry point
2. **SessionService** manages conversation history and state
3. **ArtifactService** handles binary data separately from events
4. **Events** are the fundamental units - everything is an event
5. **State** is updated via events with `state_delta`
6. **Agents** can be composed: Sequential, Parallel, Loop, or Custom
7. All communication happens through the async event stream
8. Services are pluggable - swap implementations based on needs

This architecture provides a clean separation of concerns:
- **Runner**: Orchestration
- **Services**: Persistence
- **Agents**: Logic
- **Events**: Communication
- **State**: Memory