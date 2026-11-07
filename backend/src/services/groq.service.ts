import Groq from 'groq-sdk';
import { env } from '../config/env.js';
import { Logger } from '../common/utils/logger.js';

export interface ParsedTransactionResult {
  isTransaction: boolean;
  type?: 'INCOME' | 'EXPENSE';
  amount?: number;
  category?: string;
  description?: string;
  account?: string;
  date?: string;
  needsClarification: boolean;
  clarificationMessage?: string;
}

export class GroqService {
  private client: Groq | null = null;

  constructor() {
    if (env.GROQ_API_KEY && env.GROQ_API_KEY.trim() !== '') {
      this.client = new Groq({
        apiKey: env.GROQ_API_KEY,
      });
      Logger.info('Groq AI client initialized successfully.');
    } else {
      Logger.warn('GROQ_API_KEY is not configured. GroqService running in placeholder mode.');
    }
  }

  public isConfigured(): boolean {
    return this.client !== null;
  }

  /**
   * Parse natural language transaction input into structured financial transaction data.
   * Uses Groq LLM endpoint. Backend retains full validation and database persistence responsibility.
   */
  public async parseNaturalLanguageTransaction(
    text: string
  ): Promise<ParsedTransactionResult> {
    if (!this.client) {
      Logger.warn(`AI parsing requested but GROQ_API_KEY is not set. Input: "${text}"`);
      return {
        isTransaction: false,
        needsClarification: true,
        clarificationMessage:
          'Layanan AI Groq belum dikonfigurasi dengan API key yang valid di server.',
      };
    }

    const systemPrompt = `Anda adalah asisten pencatatan keuangan pribadi bernama Personal Finance Tracker.
Tugas Anda mengekstrak informasi keuangan dari teks bahasa Indonesia menjadi format JSON strictly structured:
{
  "isTransaction": boolean,
  "type": "INCOME" | "EXPENSE" | null,
  "amount": number | null,
  "category": string | null,
  "description": string | null,
  "needsClarification": boolean,
  "clarificationMessage": string | null
}

Aturan:
1. Nominal wajib diekstrak dalam angka murni (cth: "50.000" -> 50000, "5 jt" -> 5000000).
2. Jika nominal tidak disebutkan atau kurang jelas, set "needsClarification": true dan berikan "clarificationMessage" yang sopan meminta nominal transaksi.
3. Kategori disesuaikan dengan konteks (Transportasi, Makanan & Minuman, Gaji, Belanja, dll).
4. Jangan pernah mengarang nominal jika tidak ada di teks.`;

    try {
      const response = await this.client.chat.completions.create({
        model: env.GROQ_MODEL,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: text },
        ],
        response_format: { type: 'json_object' },
        temperature: 0.1,
      });

      const content = response.choices[0]?.message?.content;
      if (!content) {
        throw new Error('Groq returned empty response');
      }

      const parsed: ParsedTransactionResult = JSON.parse(content);
      return parsed;
    } catch (error) {
      Logger.error('Failed to parse transaction with Groq:', error);
      throw error;
    }
  }
}

export const groqService = new GroqService();

