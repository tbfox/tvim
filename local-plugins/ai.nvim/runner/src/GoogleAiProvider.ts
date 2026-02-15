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
}

