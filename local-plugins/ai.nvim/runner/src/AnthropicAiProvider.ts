import Anthropic from "@anthropic-ai/sdk";
import { AiProvider } from "./AiProvider";

export class AnthropicAiProvider extends AiProvider {
    private client: Anthropic = new Anthropic({
      apiKey: Bun.env.CLAUDE_API_KEY 
    })
    override async getResponseFromProvider(prompt: string) {
        const responseObj = await this.client.messages.create({
          max_tokens: 1024,
          messages: [{ role: "user", content: prompt }],
          model: "claude-haiku-4-5-20251001"
        });

        if (responseObj.content.length === 0) throw "Anthropic response array is empty."
        if (!responseObj.content[0]) throw new Error ("Anthropic response array does not have valid content.") 

        // @ts-ignore
        const response = responseObj.content[0].text

        if (!response) throw new Error ("Anthropic response array does not have a valid text field.") 
    
        return response
    }
}

