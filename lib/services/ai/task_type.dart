enum TaskType {
  programGeneration,
  smartReply,
  translation,
  vision,
  summary,
  coachInsight,
}

enum AiProvider { cerebras, groq, gemini, openrouter }

// Ordered fallback chains per task type.
// vision has no fallback by design (Gemini only).
const Map<TaskType, List<AiProvider>> kProviderChain = {
  TaskType.programGeneration: [AiProvider.cerebras, AiProvider.gemini, AiProvider.groq],
  TaskType.smartReply:        [AiProvider.groq, AiProvider.cerebras, AiProvider.openrouter],
  TaskType.translation:       [AiProvider.groq, AiProvider.cerebras, AiProvider.openrouter],
  TaskType.vision:            [AiProvider.gemini],
  TaskType.summary:           [AiProvider.cerebras, AiProvider.gemini],
  TaskType.coachInsight:      [AiProvider.cerebras, AiProvider.gemini, AiProvider.groq],
};
