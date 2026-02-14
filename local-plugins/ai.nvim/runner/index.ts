import { join } from "path";
import { parseArgs } from 'util'
import { ConversationHistory } from './src/history'
import { getClaudeResponse } from "./src/anthropic";
import { getGeminiResponse } from "./src/google";

global.ROOT_STATE_FOLDER = join(Bun.env.HOME, '.local', 'share', 'tbfox_ai')
global.HISTORY_PATH = join(global.ROOT_STATE_FOLDER, 'history.sqlite')
global.LOG_FILE_PATH = join(global.ROOT_STATE_FOLDER, 'logs.log')

const { positionals } = parseArgs({
  args: Bun.argv,
  strict: true,
  allowPositionals: true,
});

const history = new ConversationHistory(global.HISTORY_PATH)

try {
    const prompt = positionals[2]!
    if (Bun.env.AI_PROVIDER === 'ANTHROPIC') {
        const response = await getClaudeResponse(prompt)
        console.log(response);
        history.save(prompt, response)
    } else if (Bun.env.AI_PROVIDER === 'GOOGLE') {
        const response = await getGeminiResponse(prompt)
        console.log(response);
        history.save(prompt, response)
    } else {
        throw new Error(`AI Provider ${Bun.env.AI_PROVIDER} not found or not defined. Check env variable 'AI_PROVIDER'`)
    }
} catch(e) {
    console.log(e)
}

