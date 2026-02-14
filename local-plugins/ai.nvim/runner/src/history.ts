import { Database } from 'bun:sqlite';
import { existsSync, mkdirSync } from 'fs';
import { dirname } from 'path';
import Logger from './logger';

class ConversationHistory {
  db: Database;
  
  constructor(dbPath: string) {
    // Ensure directory exists
    const dir = dirname(dbPath);
    if (!existsSync(dir)) {
      mkdirSync(dir, { recursive: true });
    }
    
    // Check if database file exists
    const dbExists = existsSync(dbPath);
    
    this.db = new Database(dbPath);
    
    if (!dbExists) {
      Logger.info(`Database created at: '${dbPath}'`);
    } 
    
    this.init();
  }
  
  init() {
    this.db.run(`
      CREATE TABLE IF NOT EXISTS conversations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        prompt TEXT NOT NULL,
        response TEXT NOT NULL,
        prompt_embedding TEXT,
        response_embedding TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    this.db.run('CREATE INDEX IF NOT EXISTS idx_timestamp ON conversations(timestamp)');
  }
  
  getNthMostRecent(count: number) {
    return this.db.query(` SELECT * FROM conversations ORDER BY timestamp DESC LIMIT 1 OFFSET ?`).get(count);
  }
  save(
    prompt: string, 
    response: string, 
    promptEmbedding?: number[], 
    responseEmbedding?: number[]
  ): number {
    const result = this.db.run(
      `INSERT INTO conversations 
       (timestamp, prompt, response, prompt_embedding, response_embedding) 
       VALUES (?, ?, ?, ?, ?)`,
      [
        Date.now(),
        prompt,
        response,
        promptEmbedding ? JSON.stringify(promptEmbedding) : null,
        responseEmbedding ? JSON.stringify(responseEmbedding) : null
      ]
    );
    
    Logger.info(`Saving -- ${prompt.substring(0, 16)}...`);
    return result.lastInsertRowid as number;
  }
  
  getById(id: number) {
    Logger.info(`Getting prompt by id '${id}'`);
    return this.db.query('SELECT * FROM conversations WHERE id = ?').get(id);
  }
  
  getRecent(limit = 100) {
    Logger.info(`Getting recent ${limit} prompts.`);
    return this.db.query('SELECT * FROM conversations ORDER BY timestamp DESC LIMIT ?')
      .all(limit);
  }
  
  getAll() {
    Logger.info(`Getting all prompts.`);
    return this.db.query('SELECT * FROM conversations ORDER BY id ASC').all();
  }
  
  searchByPromptEmbedding(queryEmbedding: number[], limit = 10) {
    // Get all conversations that have prompt embeddings
    const rows = this.db.query(
      'SELECT * FROM conversations WHERE prompt_embedding IS NOT NULL ORDER BY timestamp DESC LIMIT ?'
    ).all(1000) as any[];
    
    const withScores = rows.map(row => ({
      ...row,
      prompt_embedding: JSON.parse(row.prompt_embedding),
      response_embedding: row.response_embedding ? JSON.parse(row.response_embedding) : null,
      score: cosineSimilarity(queryEmbedding, JSON.parse(row.prompt_embedding))
    }));
    
    const sorted = withScores.sort((a, b) => b.score - a.score).slice(0, limit);
    Logger.info(`Searching by prompt embedding, top log has id '${sorted[0]}'.`);
    return sorted
  }
  
  searchByResponseEmbedding(queryEmbedding: number[], limit = 10) {
    // Get all conversations that have response embeddings
    const rows = this.db.query(
      'SELECT * FROM conversations WHERE response_embedding IS NOT NULL ORDER BY timestamp DESC LIMIT ?'
    ).all(1000) as any[];
    
    const withScores = rows.map(row => ({
      ...row,
      prompt_embedding: row.prompt_embedding ? JSON.parse(row.prompt_embedding) : null,
      response_embedding: JSON.parse(row.response_embedding),
      score: cosineSimilarity(queryEmbedding, JSON.parse(row.response_embedding))
    }));
    
    const sorted = withScores.sort((a, b) => b.score - a.score).slice(0, limit);
    Logger.info(`Searching by response embedding, top log has id '${sorted[0]}'.`);
    return withScores.sort((a, b) => b.score - a.score).slice(0, limit);
  }
  
  setEmbeddings(id: number, promptEmbedding?: number[], responseEmbedding?: number[]) {
    const updates: string[] = [];
    const values: any[] = [];
    
    if (promptEmbedding) {
      updates.push('prompt_embedding = ?');
      values.push(JSON.stringify(promptEmbedding));
    }
    
    if (responseEmbedding) {
      updates.push('response_embedding = ?');
      values.push(JSON.stringify(responseEmbedding));
    }
    
    if (updates.length === 0) return;
    
    values.push(id);
    
    this.db.run(
      `UPDATE conversations SET ${updates.join(', ')} WHERE id = ?`,
      values
    );
    Logger.info(`Set embeddings for prompt with id '${id}'`);
  }
  
  close() {
    this.db.close();
  }
}

function cosineSimilarity(a: number[], b: number[]): number {
    if (a.length !== b.length) {
      throw new Error('Vectors must have same length');
    }

    const dot = a.reduce((sum, val, i) => sum + val * b[i], 0);
    const magA = Math.sqrt(a.reduce((sum, val) => sum + val * val, 0));
    const magB = Math.sqrt(b.reduce((sum, val) => sum + val * val, 0));

    if (magA === 0 || magB === 0) return 0;

    return dot / (magA * magB);
}

export default ConversationHistory;
export { ConversationHistory, cosineSimilarity };
