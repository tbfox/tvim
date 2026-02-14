import { appendFileSync } from 'fs';

type LogLevel = 'INFO' | 'WARN' | "ERROR"

class Logger {
  static #formatLog(level: LogLevel, message: string) {
    const timestamp = new Date().toISOString();
    return `${level}||${timestamp}||${message}\n`
  }

  static #writeLog(level: LogLevel, message: string) {
    const logLine = this.#formatLog(level, message);
    try {
      appendFileSync(global.LOG_FILE_PATH, logLine);
    } catch (error) {
      console.error('Failed to write to log file:', error);
    }
  }

  static info(message: string) {
    this.#writeLog('INFO', message);
  }

  static warning(message: string) {
    this.#writeLog('WARN', message);
  }

  static error(message: string) {
    this.#writeLog('ERROR', message);
  }
}

export default Logger;
