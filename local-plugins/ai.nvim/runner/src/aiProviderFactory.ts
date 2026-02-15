import type { AiProvider } from "./AiProvider"
import { AnthropicAiProvider } from "./AnthropicAiProvider"
import { GoogleAiProvider } from "./GoogleAiProvider"

export function aiProviderFactory(): AiProvider | null {
    if (Bun.env.AI_PROVIDER === 'ANTHROPIC') return new AnthropicAiProvider()
    if (Bun.env.AI_PROVIDER === 'GOOGLE') return new GoogleAiProvider()
    return null
}
