import { fileIo } from '@kit.CoreFileKit';
import { classAttribute, semesterAttribute, exportSemester } from '../constants/ScheduleSources';

interface storedSchedule {
  defaultSemester: number,
  semesters: exportSemester[]
}

let scheduleFilePath: string = '';
let scheduleCache: storedSchedule | null = null;
let fileReady: boolean = false;

/**
 * 初始化 ScheduleStorage。必须在任何读写操作之前调用一次（EntryAbility.onCreate 中调用）。
 * @param context 应用上下文
 */
export function init(context: Context): void {
  scheduleFilePath = `${context.filesDir}/scheduleData.json`;
  fileReady = true;
  loadSchedule();
}

export function isReady(): boolean {
  return scheduleFilePath !== '' && fileReady;
}

function loadSchedule(): storedSchedule {
  if (scheduleCache !== null) {
    return scheduleCache;
  }
  try {
    if (fileIo.accessSync(scheduleFilePath)) {
      scheduleCache = JSON.parse(fileIo.readTextSync(scheduleFilePath)) as storedSchedule;
    }
  } catch (e) {
    console.error('ScheduleStorage: failed to load schedule file:', JSON.stringify(e));
  }
  if (scheduleCache === null) {
    scheduleCache = { defaultSemester: 0, semesters: [] };
  }
  return scheduleCache;
}

function flushSchedule(): void {
  try {
    const file = fileIo.openSync(scheduleFilePath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    fileIo.writeSync(file.fd, JSON.stringify(scheduleCache ?? { defaultSemester: 0, semesters: [] }));
    fileIo.closeSync(file);
    fileReady = true;
  } catch (e) {
    console.error('ScheduleStorage: failed to save schedule file:', JSON.stringify(e));
  }
}

export function getDefaultSemester(): number {
  return loadSchedule().defaultSemester;
}

export function setDefaultSemester(index: number): void {
  const data = loadSchedule();
  data.defaultSemester = index;
  scheduleCache = data;
  flushSchedule();
}

export function getSemesters(): semesterAttribute[] {
  return loadSchedule().semesters.map(entry => entry.attribute);
}

export function setSemesters(attributes: semesterAttribute[]): void {
  const data = loadSchedule();
  data.semesters = attributes.map(attribute => {
    const existing = data.semesters.find(entry => entry.attribute.createTime === attribute.createTime);
    const entry: exportSemester = {
      attribute: attribute,
      courses: existing ? existing.courses : []
    };
    return entry;
  });
  scheduleCache = data;
  flushSchedule();
}

export function getCourses(createTime: number): classAttribute[] {
  const data = loadSchedule();
  const entry = data.semesters.find(item => item.attribute.createTime === createTime);
  return entry ? entry.courses : [];
}

export function setCourses(createTime: number, courses: classAttribute[]): void {
  const data = loadSchedule();
  const entry = data.semesters.find(item => item.attribute.createTime === createTime);
  if (entry) {
    entry.courses = courses;
  } else {
    data.semesters.push({ attribute: { name: '', source: '', createTime: createTime, beginTime: 0, totalWeekNum: 0 }, courses: courses });
  }
  scheduleCache = data;
  flushSchedule();
}

export function deleteSemesterData(createTime: number): void {
  const data = loadSchedule();
  data.semesters = data.semesters.filter(item => item.attribute.createTime !== createTime);
  scheduleCache = data;
  flushSchedule();
}

/**
 * 清除全部课表数据（用于故障恢复页面）。
 */
export function clearScheduleData(): void {
  scheduleCache = { defaultSemester: 0, semesters: [] };
  flushSchedule();
}

/**
 * 将旧版（2.1.1 及以前）保存在 UnifyPreference 中的课表数据导入本地 JSON 文件。
 * @param defaultSemester 旧版默认学期编号
 * @param attributes 旧版学期属性列表
 * @param coursesByCreateTime 旧版各学期课程数据（键为 createTime）
 */
export function importLegacyData(defaultSemester: number, attributes: semesterAttribute[], coursesByCreateTime: Record<string, classAttribute[]>): void {
  const data = loadSchedule();
  data.semesters = attributes.map(attribute => {
    const entry: exportSemester = {
      attribute: attribute,
      courses: coursesByCreateTime[String(attribute.createTime)] || []
    };
    return entry;
  });
  if (attributes.length > 0) {
    data.defaultSemester = defaultSemester >= 0 && defaultSemester < attributes.length ? defaultSemester : 0;
  }
  scheduleCache = data;
  if (data.semesters.length > 0) {
    flushSchedule();
  }
}