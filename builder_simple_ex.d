# 1. Pydantic schemas for type-safety
class ContextConfig(BaseModel):
    sml_grounding: bool
    persona_info: bool
    pattern_library: bool
    few_shot_examples: bool

class ContextPacket(BaseModel):
    sml: Optional[Dict]
    persona: Optional[Dict]
    patterns: Optional[List]
    examples: Optional[List]

# 2. Simple context builder (BaseAgent - no LLM)
class ContextBuilderAgent(BaseAgent):
    async def _run_async_impl(self, ctx):
        config = ContextConfig(**ctx.session.state["context_config"])
        
        packet = {}
        if config.sml_grounding:
            packet["sml"] = load_sml_from_json()
        if config.persona_info:
            packet["persona"] = load_persona_from_json()
        
        yield Event(
            author=self.name,
            actions=EventActions(
                state_delta={"context_packet": packet}
            )
        )

# 3. Question generator (Agent - uses LLM)
generator = Agent(
    name="generator",
    model="gemini-2.0-flash-exp",
    instruction="Context: {{ context_packet }}\nGenerate plan for: {{ seed_question }}",
    output_key="question_plan"
)

# 4. Pipeline
pipeline = SequentialAgent(
    sub_agents=[ContextBuilderAgent(), generator]
)
