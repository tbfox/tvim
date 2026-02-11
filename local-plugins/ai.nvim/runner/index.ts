import Anthropic from "@anthropic-ai/sdk";
import { parseArgs } from 'util'

const { positionals } = parseArgs({
  args: Bun.argv,
  strict: true,
  allowPositionals: true,
});

try {
    const client = new Anthropic({
      apiKey: Bun.env.CLAUDE_API_KEY 
    });
    
    const content = positionals[2]
    if (!content) throw "No content provided."

    const message = await client.messages.create({
      max_tokens: 1024,
      messages: [{ role: "user", content }],
      model: "claude-haiku-4-5-20251001"
    });
    if (message.content.length === 0) throw "AI Response length array was 0."

    // @ts-ignore
    console.log(message.content[0]!.text);
} catch(e) {
    console.log(e)
}

