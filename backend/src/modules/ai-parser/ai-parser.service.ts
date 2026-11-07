import { prisma } from '../../config/database.js';
import { env } from '../../config/env.js';
import { groqService, ParsedTransactionResult } from '../../services/groq.service.js';
import { Logger } from '../../common/utils/logger.js';

export class AiParserService {
  public async parseTransactionMessage(
    text: string,
    userId?: string
  ): Promise<ParsedTransactionResult> {
    const startTime = Date.now();
    let result: ParsedTransactionResult;
    let status = 'SUCCESS';
    let errorMessage: string | undefined;

    try {
      result = await groqService.parseNaturalLanguageTransaction(text);

      if (result.needsClarification || !result.amount) {
        status = 'NEED_CLARIFICATION';
      }
    } catch (error) {
      status = 'FAILED';
      errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error(`Error in AiParserService: ${errorMessage}`);
      result = {
        isTransaction: false,
        needsClarification: true,
        clarificationMessage: 'Gagal memproses pesan secara otomatis. Mohon periksa kembali pesan Anda.',
      };
    }

    const durationMs = Date.now() - startTime;

    // Persist AIProcessingLog for audit & debugging
    try {
      await prisma.aIProcessingLog.create({
        data: {
          userId,
          rawInput: text,
          model: env.GROQ_MODEL,
          parsedResult: JSON.parse(JSON.stringify(result)),
          status,
          errorMessage,
          latencyMs: durationMs,
        },
      });
    } catch (logErr) {
      Logger.warn('Failed to save AIProcessingLog to database:', logErr);
    }

    return result;
  }
}

export const aiParserService = new AiParserService();

