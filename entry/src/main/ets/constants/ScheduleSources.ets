
import UnifiedPreferences from '../utils/UnifyPreference';

export interface classAttribute {
  name: string,
  teacher: string,
  weekOfTerm: number[],    // 以枚举形式写出哪几周
  timeSpan: number[],      // 包含完整的第几节课
  dayOfWeek: number,
  location: string,
  id: string,
  color: string,
  priority: number,
  credits: string // 防止小数精度丢失
}

export interface semesterAttribute {
  name: string, // 名称
  createTime: number, // 课表创建时间戳，用于读取不同课表
  source: string, // 最后一次编辑来源
  beginTime: number, // 学期开始时间戳
  totalWeekNum: number // 课程最大周数
}

export interface exportSemester {
  attribute: semesterAttribute,
  courses: classAttribute[]
};

export interface exportedData {
  exportTime: number,
  scheduleVersion: string,
  defaultSemester: number,
  semesters: exportSemester[]
};

export let remindBefore: number[] = [];
export let examRemindBefore: number[] = [];

export function initSchedulePre() {
  remindBefore[0] = UnifiedPreferences.getNumberSync('remindBefore', 0) as number;
  if (remindBefore[0] == -1)
    remindBefore = [];
  examRemindBefore[0] = UnifiedPreferences.getNumberSync('examRemindBefore', 0) as number;
  if (examRemindBefore[0] == -1)
    examRemindBefore = [];
}

export function setRemindBefore(minute: number) {
  if (minute == -1)
    remindBefore = [];
  else
    remindBefore[0] = minute;
  UnifiedPreferences.putSync('remindBefore', minute);
}

export function setExamRemindBefore(minute: number) {
  if (minute == -1)
    examRemindBefore = [];
  else
    examRemindBefore[0] = minute;
  UnifiedPreferences.putSync('examRemindBefore', minute);
}

// 第几节课 -> 上课时间
export const commonClassTime: string[][] = [
  ['07:21', '11:45'],    // 排除[0]
  ['07:50', '08:35'], ['08:40', '09:25'], ['09:45', '10:30'], ['10:35', '11:20'], ['11:25', '12:10'],    // 上午
  ['14:00', '14:45'], ['14:50', '15:35'], ['15:55', '16:40'], ['16:45', '17:30'], ['17:35', '18:20'],    // 下午
  ['18:40', '19:25'], ['19:30', '20:15'], ['20:20', '21:05'], ['21:10', '21:55']    // 晚上
];

export const commonClassStamp: number[][]= [
  [26460000, 42300000],
  [28200000, 30900000], [31200000, 33900000], [35100000, 37800000], [38100000, 40800000], [41000000, 43800000],
  [50400000, 53100000], [53400000, 56100000], [57300000, 60000000], [60300000, 63000000], [63300000, 66000000],
  [67200000, 69900000], [70200000, 72900000], [73200000, 75900000], [76200000, 78900000]
];


/**
 * 校验 JSON.parse 解析后的对象是否符合 exportedData 接口规范
 * @param data JSON.parse 解析后的原始对象（仅此处用 object 类型）
 * @returns string[] 校验结果和错误信息
 */
export function validateExportedData(data: object): string {
  // 第一步：校验顶层结构（原生判断）
  if (typeof data !== 'object' || data === null || Array.isArray(data)) {
    return 'exportedData 必须是一个非空对象';
  }

  // 类型断言为显式定义的类型（仅用于 TS 编译，运行时靠原生判断）
  const exportedData = data as exportedData;

  // ------------------------------
  // 校验顶层字段（typeof 判断）
  // ------------------------------
  // 1. exportTime
  if (exportedData.exportTime === undefined || exportedData.exportTime === null) {
    return 'exportedData 缺少必填字段: exportTime';
  } else if (typeof exportedData.exportTime !== 'number') {
    return 'exportedData.exportTime 必须是 number 类型';
  } else if (exportedData.exportTime <= 0) {
    return 'exportedData.exportTime 必须是有效的时间戳（正数）';
  }

  // 2. scheduleVersion
  if (exportedData.scheduleVersion === undefined || exportedData.scheduleVersion === null) {
    return 'exportedData 缺少必填字段: scheduleVersion';
  } else if (typeof exportedData.scheduleVersion !== 'string') {
    return 'exportedData.scheduleVersion 必须是 string 类型';
  }

  // 3. defaultSemester
  if (exportedData.defaultSemester === undefined || exportedData.defaultSemester === null) {
    return 'exportedData 缺少必填字段: defaultSemester';
  } else if (typeof exportedData.defaultSemester !== 'number') {
    return 'exportedData.defaultSemester 必须是 number 类型';
  } else if (exportedData.defaultSemester < 0) {
    return 'exportedData.defaultSemester 必须是非负整数';
  }

  // 4. semesters
  if (exportedData.semesters === undefined || exportedData.semesters === null) {
    return 'exportedData 缺少必填字段: semesters';
  } else if (!Array.isArray(exportedData.semesters)) {
    return 'exportedData.semesters 必须是数组类型';
  }

  if (Array.isArray(exportedData.semesters)) {
    // 显式指定 semester: exportSemester, semesterIndex: number
    for (let semesterIndex = 0; semesterIndex < exportedData.semesters.length; semesterIndex++) {
      const semester = exportedData.semesters[semesterIndex];
      const semesterPath = `exportedData.semesters[${semesterIndex}]`;

      // 运行时兜底校验：确保 semester 是纯对象
      if (typeof semester !== 'object' || semester === null || Array.isArray(semester)) {
        return `${semesterPath} 必须是一个非空对象`;
      }

      // 校验 attribute 字段
      if (semester.attribute === undefined || semester.attribute === null) {
        return `${semesterPath} 缺少必填字段: attribute`;
      } else if (typeof semester.attribute !== 'object' || semester.attribute === null || Array.isArray(semester.attribute)) {
        return `${semesterPath}.attribute 必须是非空对象`;
      }

      // 校验 courses 字段
      if (semester.courses === undefined || semester.courses === null) {
        return `${semesterPath} 缺少必填字段: courses`;
      } else if (!Array.isArray(semester.courses)) {
        return `${semesterPath}.courses 必须是数组类型`;
      }

      // ------------------------------
      // 校验 semesterAttribute
      // ------------------------------
      if (typeof semester.attribute === 'object' && semester.attribute !== null && !Array.isArray(semester.attribute)) {
        const attribute = semester.attribute;
        const attributePath = `${semesterPath}.attribute`;

        // 1. name
        if (attribute.name === undefined || attribute.name === null) {
          return `${attributePath} 缺少必填字段: name`;
        } else if (typeof attribute.name !== 'string') {
          return `${attributePath}.name 必须是 string 类型`;
        }

        // 2. createTime
        if (attribute.createTime === undefined || attribute.createTime === null) {
          return `${attributePath} 缺少必填字段: createTime`;
        } else if (typeof attribute.createTime !== 'number') {
          return `${attributePath}.createTime 必须是 number 类型`;
        } else if (attribute.createTime <= 0) {
          return `${attributePath}.createTime 必须是有效的时间戳`;
        }

        // 3. source
        if (attribute.source === undefined || attribute.source === null) {
          return `${attributePath} 缺少必填字段: source`;
        } else if (typeof attribute.source !== 'string') {
          return `${attributePath}.source 必须是 string 类型`;
        }

        // 4. beginTime
        if (attribute.beginTime === undefined || attribute.beginTime === null) {
          return `${attributePath} 缺少必填字段: beginTime`;
        } else if (typeof attribute.beginTime !== 'number') {
          return `${attributePath}.beginTime 必须是 number 类型`;
        } else if (attribute.beginTime <= 0) {
          return `${attributePath}.beginTime 必须是有效的时间戳`;
        }

        // 5. totalWeekNum
        if (attribute.totalWeekNum === undefined || attribute.totalWeekNum === null) {
          return `${attributePath} 缺少必填字段: totalWeekNum`;
        } else if (typeof attribute.totalWeekNum !== 'number') {
          return `${attributePath}.totalWeekNum 必须是 number 类型`;
        } else if (attribute.totalWeekNum < 0 || !Number.isInteger(attribute.totalWeekNum)) {
          return `${attributePath}.totalWeekNum 必须是非负整数`;
        }
      }

      // 校验 courses 数组
      if (Array.isArray(semester.courses)) {
        for (let courseIndex = 0; courseIndex < semester.courses.length; courseIndex++){
          const course = semester.courses[courseIndex];
          const coursePath = `${semesterPath}.courses[${courseIndex}]`;

          // 运行时兜底校验
          if (typeof course !== 'object' || course === null || Array.isArray(course)) {
            return `${coursePath} 必须是一个非空对象`;
          }

          // 1. name
          if (course.name === undefined || course.name === null) {
            return `${coursePath} 缺少必填字段: name`;
          } else if (typeof course.name !== 'string') {
            return `${coursePath}.name 必须是 string 类型`;
          }

          // 2. teacher
          if (course.teacher === undefined || course.teacher === null) {
            return `${coursePath} 缺少必填字段: teacher`;
          } else if (typeof course.teacher !== 'string') {
            return `${coursePath}.teacher 必须是 string 类型`;
          }

          // 3. weekOfTerm
          if (course.weekOfTerm === undefined || course.weekOfTerm === null) {
            return `${coursePath} 缺少必填字段: weekOfTerm`;
          } else if (!Array.isArray(course.weekOfTerm)) {
            return `${coursePath}.weekOfTerm 必须是数组类型`;
          } else if (!course.weekOfTerm.every(item => typeof item === 'number' && Number.isInteger(item) && item > 0)) {
            return `${coursePath}.weekOfTerm 必须是正整数数组`;
          }

          // 4. timeSpan
          if (course.timeSpan === undefined || course.timeSpan === null) {
            return `${coursePath} 缺少必填字段: timeSpan`;
          } else if (!Array.isArray(course.timeSpan)) {
            return `${coursePath}.timeSpan 必须是数组类型`;
          } else if (!course.timeSpan.every(item => typeof item === 'number' && Number.isInteger(item) && item > 0)) {
            return `${coursePath}.timeSpan 必须是正整数数组`;
          }

          // 5. dayOfWeek
          if (course.dayOfWeek === undefined || course.dayOfWeek === null) {
            return `${coursePath} 缺少必填字段: dayOfWeek`;
          } else if (typeof course.dayOfWeek !== 'number') {
            return `${coursePath}.dayOfWeek 必须是 number 类型`;
          } else if (!Number.isInteger(course.dayOfWeek) || course.dayOfWeek < 0 || course.dayOfWeek > 6) {
            return `${coursePath}.dayOfWeek 必须是 0-6 的整数`;
          }

          // 6. location
          if (course.location === undefined || course.location === null) {
            return `${coursePath} 缺少必填字段: location`;
          } else if (typeof course.location !== 'string') {
            return `${coursePath}.location 必须是 string 类型`;
          }

          // 7. id
          if (course.id === undefined || course.id === null) {
            return `${coursePath} 缺少必填字段: id`;
          } else if (typeof course.id !== 'string') {
            return `${coursePath}.id 必须是 string 类型`;
          }

          // 8. color
          if (course.color === undefined || course.color === null) {
            return `${coursePath} 缺少必填字段: color`;
          } else if (typeof course.color !== 'string') {
            return `${coursePath}.color 必须是 string 类型`;
          }

          // 9. priority
          if (course.priority === undefined || course.priority === null) {
            return `${coursePath} 缺少必填字段: priority`;
          } else if (typeof course.priority !== 'number') {
            return `${coursePath}.priority 必须是 number 类型`;
          } else if (!Number.isInteger(course.priority) || course.priority < 0) {
            return `${coursePath}.priority 必须是非负整数`;
          }

          // 10. credits
          if (course.credits === undefined || course.credits === null) {
            return `${coursePath} 缺少必填字段: credits`
          } else if (typeof course.credits !== 'string') {
            return `${coursePath}.credits 必须是 string 类型`
          }
        }
      }
    }
  }

  return '';
}

export enum COVER_MODE { COVER, COVER_DUPLICATE, APPEND };