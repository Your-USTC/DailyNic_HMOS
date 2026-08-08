import { common } from '@kit.AbilityKit';
import { picker, fileIo, fileUri } from '@kit.CoreFileKit';
import { singleQuestion } from './constants';


export async function readDataFromCsv(hostContext: common.UIAbilityContext): Promise<string[]> {
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
      return result;
    } else {
      return [];
    }
  } catch(err) {
    return [];
  }
}


function parseCsvLine(line: string): string[] {
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

export function getObjectFromCsv(data: string[]): singleQuestion[] {
  const result: singleQuestion[] = [];
  for (let i = 1; i < data.length; i++) {
    const line = data[i];
    if (line.trim() === '') break;
    const fields = parseCsvLine(line);
    if (fields.length < 10) continue;
    const typeMap: Record<string, 'single' | 'multiple' | 'blank'> = {
      '单选题': 'single',
      '多选题': 'multiple',
      '填空题': 'blank'
    };
    const optionCount = parseInt(fields[9], 10) || 0;
    const options: string[] = [];
    for (let j = 0; j < optionCount; j++) {
      if (fields[10 + j] !== undefined) {
        options.push(fields[10 + j]);
      }
    }
    if (fields[1] === '填空题')
      fields[5] = options[0];
    result.push({
      section: fields[0],
      context: fields[2],
      type: typeMap[fields[1]] || 'single',
      answer: fields[5],
      analysis: fields[6] || undefined,
      difficulty: fields[7] || undefined,
      knowledgePoint: fields[8] || undefined,
      optionCount: optionCount,
      options: options,
      starred: false,
      ignore: false
    });
  }
  return result;
}