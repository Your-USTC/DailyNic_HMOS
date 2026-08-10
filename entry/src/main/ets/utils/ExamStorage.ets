import { fileIo } from '@kit.CoreFileKit';

export interface examAttribute {
  id: string,
  type: string,
  name: string,
  date: string,
  classroom: string,
  building: string,
  campus: string,
  info: string,
  beginTimeStamp: number,
  endTimeStamp: number,
  importance: number
}

let examFilePath: string = '';
let examCache: examAttribute[] | null = null;

/**
 * 初始化 ExamStorage。必须在任何读写操作之前调用一次（EntryAbility.onCreate 中调用）。
 * @param context 应用上下文
 */
export function init(context: Context): void {
  examFilePath = `${context.filesDir}/examData.json`;
  loadExam();
}

function loadExam(): examAttribute[] {
  if (examCache !== null) {
    return examCache;
  }
  try {
    if (fileIo.accessSync(examFilePath)) {
      examCache = JSON.parse(fileIo.readTextSync(examFilePath)) as examAttribute[];
    }
  } catch (e) {
    console.error('ExamStorage: failed to load exam file:', JSON.stringify(e));
  }
  if (examCache === null) {
    examCache = [];
  }
  return examCache;
}

function flushExam(): void {
  try {
    const file = fileIo.openSync(examFilePath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    fileIo.writeSync(file.fd, JSON.stringify(examCache ?? []));
    fileIo.closeSync(file);
  } catch (e) {
    console.error('ExamStorage: failed to save exam file:', JSON.stringify(e));
  }
}

export function getExams(): examAttribute[] {
  return loadExam();
}

export function setExams(data: examAttribute[]): void {
  examCache = data;
  flushExam();
}

/**
 * 清除全部考试数据（用于故障恢复页面）。
 */
export function clearExamData(): void {
  examCache = [];
  flushExam();
}

/**
 * 将旧版（2.1.1 及以前）保存在 UnifyPreference 中的考试数据导入本地 JSON 文件。
 * 仅在本地尚无考试数据时写入，避免覆盖现有数据。
 * @param legacy 旧版考试列表
 */
export function importLegacyData(legacy: examAttribute[]): void {
  const data = loadExam();
  if (legacy.length > 0 && data.length === 0) {
    data.push(...legacy);
    examCache = data;
    flushExam();
  }
}