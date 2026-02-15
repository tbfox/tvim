import { join } from "path";

global.ROOT_STATE_FOLDER = join(Bun.env.HOME, '.local', 'share', 'tbfox_ai')
global.HISTORY_PATH = join(global.ROOT_STATE_FOLDER, 'history.sqlite')
global.LOG_FILE_PATH = join(global.ROOT_STATE_FOLDER, 'logs.log')

