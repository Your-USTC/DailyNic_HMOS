import { readDataFromCsv, getObjectFromCsv, defaultCsvImportConfig } from './DataTransformer';
import { createTest } from './TestManager';
import { csvImportConfig, singleQuestion } from './constants';
import { hostContext } from '../../constants/BasicConstants';

/**
 * 按 UI 中的列映射配置导入 CSV；解析不出任何题目时返回空字符串。
 */
export function importTestFromCsv(title: string, lines: string[], config: csvImportConfig): string {
  const data: singleQuestion[] = getObjectFromCsv(lines, config);
  if (data.length === 0) {
    return '';
  }
  return createTest(data, title);
}

/** 跳过配置界面，按旧版固定列格式直接导入（数据从第 2 行开始） */
export async function importNewTestWithDefaultConfig(title: string): Promise<string> {
  const file = await readDataFromCsv(hostContext());
  return importTestFromCsv(title, file.lines, defaultCsvImportConfig());
}
