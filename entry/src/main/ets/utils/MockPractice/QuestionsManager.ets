/**
 * 题库导入管道：将 UI 传来的 CSV 文本按列映射解析为题目，并落盘为一个新的题库。
 */
import { readDataFromCsv, getObjectFromCsv, defaultCsvImportConfig } from './DataTransformer';
import { bankStore } from './QuestionBankManager';
import { csvImportConfig, singleQuestion } from './constants';
import { hostContext } from '../../constants/BasicConstants';

/**
 * 按列映射配置解析 CSV 并创建题库；解析不出任何题目时返回空字符串。
 */
export function importBankFromCsv(title: string, lines: string[], config: csvImportConfig): string {
  const data: singleQuestion[] = getObjectFromCsv(lines, config);
  if (data.length === 0) {
    return '';
  }
  return bankStore.createBank(data, title);
}

/** 跳过配置界面，按旧版固定列格式直接导入（数据从第 2 行开始） */
export async function importBankWithDefaultConfig(title: string): Promise<string> {
  const file = await readDataFromCsv(hostContext());
  return importBankFromCsv(title, file.lines, defaultCsvImportConfig());
}
