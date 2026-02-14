import Anthropic from "@anthropic-ai/sdk";

export const getClaudeResponse = async (prompt: string): Promise<string> => {
    const client = new Anthropic({
      apiKey: Bun.env.CLAUDE_API_KEY 
    });
    
    if (!prompt) throw "No content provided."

    const responseObj = await client.messages.create({
      max_tokens: 1024,
      messages: [{ role: "user", content: prompt }],
      model: "claude-haiku-4-5-20251001"
    });
    if (responseObj.content.length === 0) throw "AI Response length array was 0."
    
    // @ts-ignore
    return responseObj.content[0]!.text
}
