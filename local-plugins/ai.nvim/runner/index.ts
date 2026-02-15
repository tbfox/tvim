import { join } from "path";
import { parseArgs } from 'util'
import { aiProviderFactory } from "./src/aiProviderFactory";

global.ROOT_STATE_FOLDER = join(Bun.env.HOME, '.local', 'share', 'tbfox_ai')
global.HISTORY_PATH = join(global.ROOT_STATE_FOLDER, 'history.sqlite')
global.LOG_FILE_PATH = join(global.ROOT_STATE_FOLDER, 'logs.log')

const { positionals } = parseArgs({
  args: Bun.argv,
  strict: true,
  allowPositionals: true,
});

const prompt = positionals[2]!

const provider = aiProviderFactory()

if (provider === null) {
    console.log(`Provider ${Bun.env.AI_PROVIDER} does not exist`)
    process.exit(1)
}

const response = provider.getResponse(prompt)

console.log(response);

