export class Logger {
  public static info(message: string, ...args: unknown[]): void {
    console.log(`[INFO] [${new Date().toISOString()}] ${message}`, ...args);
  }

  public static warn(message: string, ...args: unknown[]): void {
    console.warn(`[WARN] [${new Date().toISOString()}] ${message}`, ...args);
  }

  public static error(message: string, ...args: unknown[]): void {
    console.error(`[ERROR] [${new Date().toISOString()}] ${message}`, ...args);
  }

  public static debug(message: string, ...args: unknown[]): void {
    if (process.env.NODE_ENV !== 'production') {
      console.debug(`[DEBUG] [${new Date().toISOString()}] ${message}`, ...args);
    }
  }
}

