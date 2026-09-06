import { common } from '@kit.AbilityKit';
import { picker, fileIo, fileUri } from '@kit.CoreFileKit';
import {
  CSV_UNUSED_COLUMN,
  csvColumnMapping,
  csvImportConfig,
  singleQuestion
} from './constants';

export interface csvReadResult {
  lines: string[],
  fileName: string
}

export async function readDataFromCsv(hostContext: common.UIAbilityContext): Promise<csvReadResult> {
  try {
    const documentSelectOptions = new picker.DocumentSelectOptions();
    documentSelectOptions.maxSelectNumber = 1;
    documentSelectOptions.fileSuffixFilters = ["CSV（逗号分隔）|.csv"];
    const documentViewPicker = new picker.DocumentViewPicker(hostContext);
    const documentSelectResult: string[] = await documentViewPicker.select(documentSelectOptions);
    if (documentSelectResult.length > 0) {
      let result: string[] = [];
      const readerIterator = await fileIo.readLines(new fileUri.FileUri(documentSelectResult[0]).path);
      let deleteRN: string = '';
      let BaoDi: number = 0;
      for (let it = readerIterator.next(); !it.done && BaoDi < 3000; it = readerIterator.next()) {
        deleteRN = it.value.replace(/\r/g, '').replace(/\n/g, '');
        if (/^,+$/.test(deleteRN))
          break;
        result.push(deleteRN);
        BaoDi++;
      }
      return { lines: result, fileName: fileNameFromUri(documentSelectResult[0]) };
    } else {
      return { lines: [], fileName: '' };
    }
  } catch(err) {
    return { lines: [], fileName: '' };
  }
}

function fileNameFromUri(uri: string): string {
  let name = '';
  const lastSlash = uri.lastIndexOf('/');
  if (lastSlash >= 0 && lastSlash + 1 < uri.length) {
    name = uri.substring(lastSlash + 1);
    try {
      name = decodeURIComponent(name);
    } catch (e) {
      // URI 解码失败时保留原始文件名
    }
  }
  if (name.toLowerCase().endsWith('.csv')) {
    name = name.substring(0, name.length - 4);
  }
  return name === '' ? 'test' : name;
}


export function parseCsvLine(line: string): string[] {
  const result: string[] = [];
  let current = '';
  let inQuotes = false;
  for (let i = 0; i < line.length; i++) {
    const char = line[i];
    if (inQuotes) {
      if (char === '"') {
        if (i + 1 < line.length && line[i + 1] === '"') {
          current += '"';
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        current += char;
      }
    } else {
      if (char === '"') {
        inQuotes = true;
      } else if (char === ',') {
        result.push(current);
        current = '';
      } else {
        current += char;
      }
    }
  }
  result.push(current);
  return result;
}

/** 与旧版写死的解析格式保持一致：章节、题型、题目、答案、解析、难度、知识点、选项个数、选项… */
export function defaultCsvImportConfig(): csvImportConfig {
  const columns: csvColumnMapping = {
    section: 1,
    type: 2,
    context: 3,
    answer: 6,
    analysis: 7,
    difficulty: 8,
    knowledgePoint: 9,
    optionCount: 10,
    optionStart: 11
  };
  return { startRow: 2, columns: columns };
}

function containsAny(text: string, keys: string[]): boolean {
  for (let i = 0; i < keys.length; i++) {
    if (text.includes(keys[i])) {
      return true;
    }
  }
  return false;
}

/**
 * 依据首行表头关键词猜测各列含义；若首行不含可识别的表头，
 * 则退回旧版的固定列格式（数据从第 2 行开始）。
 */
export function detectCsvConfig(data: string[]): csvImportConfig {
  if (data.length === 0) {
    return defaultCsvImportConfig();
  }
  const header = parseCsvLine(data[0]);
  const col: csvColumnMapping = {
    section: CSV_UNUSED_COLUMN,
    type: CSV_UNUSED_COLUMN,
    context: CSV_UNUSED_COLUMN,
    answer: CSV_UNUSED_COLUMN,
    analysis: CSV_UNUSED_COLUMN,
    difficulty: CSV_UNUSED_COLUMN,
    knowledgePoint: CSV_UNUSED_COLUMN,
    optionCount: CSV_UNUSED_COLUMN,
    optionStart: CSV_UNUSED_COLUMN
  };
  for (let i = 0; i < header.length; i++) {
    const name = header[i].trim().toLowerCase();
    if (name === '') {
      continue;
    }
    const colNo = i + 1;
    // 注意顺序：先匹配更具体的关键词（如"答案解析"应归为解析，"选项个数"应归为个数）
    if (col.analysis < 0 && containsAny(name, ['解析', '解释', 'analysis'])) {
      col.analysis = colNo;
    } else if (col.optionCount < 0 && containsAny(name, ['选项个数', '选项数量', '选项数', 'optioncount', 'option count'])) {
      col.optionCount = colNo;
    } else if (col.optionStart < 0 && containsAny(name, ['选项', 'option'])) {
      col.optionStart = colNo;
    } else if (col.knowledgePoint < 0 && containsAny(name, ['知识点', 'knowledge'])) {
      col.knowledgePoint = colNo;
    } else if (col.difficulty < 0 && containsAny(name, ['难度', 'difficulty'])) {
      col.difficulty = colNo;
    } else if (col.answer < 0 && containsAny(name, ['答案', 'answer'])) {
      col.answer = colNo;
    } else if (col.type < 0 && containsAny(name, ['题型', '类型', 'type'])) {
      col.type = colNo;
    } else if (col.context < 0 && containsAny(name, ['题目', '题干', '题面', '问题', 'question'])) {
      col.context = colNo;
    } else if (col.section < 0 && containsAny(name, ['章节', '小节', '单元', 'section'])) {
      col.section = colNo;
    }
  }
  if (col.context < 0) {
    // 首行没有可识别的表头，退回旧版固定列格式
    return defaultCsvImportConfig();
  }
  return { startRow: 2, columns: col };
}

function columnValue(fields: string[], column: number): string {
  if (column <= 0 || column > fields.length) {
    return '';
  }
  return fields[column - 1].trim();
}

export function getObjectFromCsv(data: string[], config: csvImportConfig): singleQuestion[] {
  const result: singleQuestion[] = [];
  const cols: csvColumnMapping = config.columns;
  const typeMap: Record<string, 'single' | 'multiple' | 'blank'> = {
    '单选题': 'single',
    '单选': 'single',
    '多选题': 'multiple',
    '多选': 'multiple',
    '填空题': 'blank',
    '填空': 'blank'
  };
  for (let i = config.startRow - 1; i < data.length; i++) {
    const line = data[i];
    if (line.trim() === '') break;
    const fields = parseCsvLine(line);
    const context = columnValue(fields, cols.context);
    if (cols.context <= 0 || context === '') continue;

    let optionCount = 0;
    if (cols.optionCount > 0) {
      optionCount = parseInt(columnValue(fields, cols.optionCount), 10) || 0;
    } else if (cols.optionStart > 0) {
      // 未指定选项个数列时，把选项起始列之后的所有列都视为选项
      optionCount = Math.max(fields.length - cols.optionStart + 1, 0);
    }
    const options: string[] = [];
    for (let j = 0; j < optionCount; j++) {
      const value = columnValue(fields, cols.optionStart + j);
      if (value !== '') {
        options.push(value);
      }
    }

    const answer = columnValue(fields, cols.answer);
    const typeText = columnValue(fields, cols.type);
    let type = typeMap[typeText];
    if (type === undefined) {
      // 无题型列时按实际选项推断：没有选项即视为填空题
      if (options.length === 0) {
        type = 'blank';
      } else if (answer.replace(/[^A-Za-z]/g, '').length > 1) {
        type = 'multiple';
      } else {
        type = 'single';
      }
    }
    // 沿用旧格式约定：填空题答案列缺省时取第一道选项
    let finalAnswer = answer;
    if (type === 'blank' && answer === '' && options.length > 0) {
      finalAnswer = options[0];
    }
    result.push({
      section: columnValue(fields, cols.section),
      context: context,
      type: type,
      answer: finalAnswer,
      analysis: columnValue(fields, cols.analysis) || undefined,
      difficulty: columnValue(fields, cols.difficulty) || undefined,
      knowledgePoint: columnValue(fields, cols.knowledgePoint) || undefined,
      optionCount: options.length,
      options: options
    });
  }
  return result;
}
