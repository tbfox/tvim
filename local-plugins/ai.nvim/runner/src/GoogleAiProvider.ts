import { GoogleGenAI } from "@google/genai";
import  { AiProvider } from "./AiProvider";

export class GoogleAiProvider extends AiProvider {
    private ai: GoogleGenAI = new GoogleGenAI({});
    override async getResponseFromProvider(prompt: string): Promise<string | undefined> {
        const response = await this.ai.models.generateContent({
          model: "gemini-3-flash-preview",
          contents: prompt
        });
        return response.text
    }
    override async getEmbedding(prompt: string): Promise<number[]> {
        const response = await this.ai.models.embedContent({
            model: 'gemini-embedding-001',
            contents: prompt
        });
        if (response.embeddings === undefined || response.embeddings[0] === undefined) throw new Error('Embeddings not found from Google api')
        if (!response.embeddings[0].values) throw new Error('Embedding values not found from Google api')
        return response.embeddings[0].values
    }
}

