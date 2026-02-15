import "./init.ts"
import { parseArgs } from 'util'
import { aiProviderFactory } from "./src/aiProviderFactory";

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

const response = await provider.getResponse(prompt)

console.log(response);

