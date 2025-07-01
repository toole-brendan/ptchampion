export enum LogLevel {
  ERROR = 0,
  WARN = 1,
  INFO = 2,
  DEBUG = 3,
}

class Logger {
  private level: LogLevel;
  private isDevelopment: boolean;
  private isDebugMode: boolean;

  constructor() {
    this.isDevelopment = import.meta.env.MODE === 'development';
    this.isDebugMode = this.checkDebugMode();
    
    // Set log level based on environment
    if (this.isDevelopment || this.isDebugMode) {
      this.level = LogLevel.DEBUG;
    } else {
      this.level = LogLevel.ERROR;
    }
  }

  private checkDebugMode(): boolean {
    // Check URL parameter for debug mode
    if (typeof window !== 'undefined') {
      const urlParams = new URLSearchParams(window.location.search);
      return urlParams.get('debug') === 'true';
    }
    return false;
  }

  private shouldLog(level: LogLevel): boolean {
    return level <= this.level;
  }

  private formatMessage(level: string, message: string, data?: any): string {
    const timestamp = new Date().toISOString();
    return `[${level}] ${message}`;
  }

  error(message: string, error?: any): void {
    if (this.shouldLog(LogLevel.ERROR)) {
      console.error(this.formatMessage('ERROR', message), error || '');
    }
  }

  warn(message: string, data?: any): void {
    if (this.shouldLog(LogLevel.WARN)) {
      console.warn(this.formatMessage('WARN', message), data || '');
    }
  }

  info(message: string, data?: any): void {
    if (this.shouldLog(LogLevel.INFO)) {
      console.log(this.formatMessage('INFO', message), data || '');
    }
  }

  debug(message: string, data?: any): void {
    if (this.shouldLog(LogLevel.DEBUG)) {
      console.log(this.formatMessage('DEBUG', message), data || '');
    }
  }

  // Special method for app initialization
  appVersion(version: string, buildTime: string): void {
    // Always show version in production, but simplified
    if (!this.isDevelopment && !this.isDebugMode) {
      console.log(`PT Champion ${version}`);
    } else {
      console.log(`PT Champion ${version} (built: ${buildTime})`);
    }
  }

  // Group related logs together
  group(label: string, fn: () => void): void {
    if (this.shouldLog(LogLevel.DEBUG)) {
      console.group(label);
      fn();
      console.groupEnd();
    } else {
      fn();
    }
  }
}

// Export singleton instance
export const logger = new Logger();