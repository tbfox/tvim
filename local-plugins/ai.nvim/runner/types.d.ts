declare global {
  var ROOT_STATE_FOLDER: string;
  var HISTORY_PATH: string;
  var LOG_FILE_PATH: string;
}

declare module "bun" {
  interface Env {
    HOME: string; 
    CLAUDE_API_KEY: string;
  }
}

export {}
