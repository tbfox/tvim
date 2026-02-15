import ConversationHistory from "./history"

const history = new ConversationHistory(global.HISTORY_PATH)

export abstract class AiProvider {
    abstract getResponseFromProvider(prompt: string): Promise<string | undefined>;
    async getResponse(prompt?: string): Promise<string | null> {
        try {
            if (!prompt) throw new Error("No prompt provided.")
            const response = await this.getResponseFromProvider(prompt)
            if (!response) throw new Error("No response provided.")
            history.save(prompt, response)
            return response
        } catch (e) {
            return null
        }
    }
}
