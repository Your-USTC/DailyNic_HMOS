// 用于管理多学期的 ScheduleManager

import * as ScheduleStorage from '../ScheduleStorage';
import { classAttribute, COVER_MODE, semesterAttribute } from '../../constants/ScheduleSources';
import { colorSet, colorSetLen, extractCredits, getRandomInt } from '../tools';

function areNumberArraysEqual(a: number[], b: number[]): boolean {
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) {
    if (a[i] !== b[i]) return false;
  }
  return true;
}

/**
 * 比较两个 classAttribute 对象是否完全相同
 * @param a 第一个对象
 * @param b 第二个对象
 * @param checkMinor 是否检查非教务系统存在的属性：颜色和优先级。默认检查
 * @returns 是否完全相同
 */
export function areClassAttributesEqual(a: classAttribute, b: classAttribute, checkMinor: boolean = true): boolean {
  // 基本类型直接比较
  if (a.name !== b.name) return false;
  if (a.teacher !== b.teacher) return false;
  if (a.dayOfWeek !== b.dayOfWeek) return false;
  if (a.location !== b.location) return false;
  if (a.id !== b.id) return false;
  if (a.credits !== b.credits) return false;
  if (checkMinor) {
    if (a.color !== b.color) return false;
    if (a.priority !== b.priority) return false;
  }

  // 数组类型通过辅助函数比较
  if (!areNumberArraysEqual(a.weekOfTerm, b.weekOfTerm)) return false;
  if (!areNumberArraysEqual(a.timeSpan, b.timeSpan)) return false;

  // 所有字段都相同
  return true;
}

class ScheduleManager {
  // 所有学期
  semesters: semesterAttribute[] = [];
  // 课表页展示的默认课程（number是当前周数），通过getDisplayClassesByWeek获取整周的课程
  displayIndex: Map<number, classAttribute[]> = new Map<number, classAttribute[]>();
  // 首页及卡片展示的默认课程（number是当前周数），通过getDefaultClassesByDay获取整周的课程
  defaultIndex: Map<number, Map<number, classAttribute[]>> = new Map<number, Map<number, classAttribute[]>>();
  // 当前展示学期的编号
  displaySemester: number = 0;

  // 以下内容针对首页/服务卡片/系统日程添加
  // 默认学期的编号，通过semesters[defaultSemester]读取
  defaultSemester: number = 0;


  constructor() {
    if (ScheduleStorage.isReady()) { this.init(); }
  }

  init() {
    // 读取所有学期的信息
    this.semesters = ScheduleStorage.getSemesters();
    this.setDefaultSemester(this.displaySemester = ScheduleStorage.getDefaultSemester()); // 默认第一个是课表
    if (this.semesters.length === 0) { // 如果是第一次使用
      const currentTime = new Date();
      this.newSemester('默认', '初始自动生成', new Date(new Date(currentTime).setDate(currentTime.getDate() - currentTime.getDay())).setHours(0, 0, 0, 0), currentTime.getTime());
    }
    this.rebuildDisplayIndex(ScheduleStorage.getCourses(this.semesters[this.displaySemester].createTime));
  }


  /**
   * 根据课程列表重建课表页面展示的周索引
   * @param classes 课程列表
   * @returns undefined，但如果发生错误则返回错误信息的字符串
   */
  private rebuildDisplayIndex(classes: classAttribute[]): string | undefined {
    try {
      this.displayIndex.clear();
      for (const classItem of classes) {
        if (!classItem) {
          continue; // 跳过无效的课程项
        }
        for (const week of classItem.weekOfTerm) {
          let items = this.displayIndex.get(week);
          if (!items) {
            items = [];
            this.displayIndex.set(week, items);
          }
          items.push(classItem);
        }
      }
      return;
    } catch(err) {
      return JSON.stringify(err);
    }
  }


  /**
   * 根据课程列表重建默认页面展示的周索引
   * @param classes 课程列表
   * @returns undefined，但如果发生错误则返回错误信息的字符串
   */
  private rebuildDefaultIndex(classes: classAttribute[]): string | undefined {
    try {
      this.defaultIndex.clear();
      for (const classItem of classes) {
        for (const week of classItem.weekOfTerm) {
          if (!this.defaultIndex.has(week)) {
            this.defaultIndex.set(week, new Map());
          }
          const dayMap = this.defaultIndex.get(week)!;

          if (!dayMap.has(classItem.dayOfWeek)) {
            dayMap.set(classItem.dayOfWeek, []);
          }
          dayMap.get(classItem.dayOfWeek)!.push(classItem);
        }
      }
      return;
    } catch(err) {
      return JSON.stringify(err);
    }
  }

  /**
   * 获取课表页面指定周的所有课程
   * @param week 周数
   * @returns 课程列表
   */
  getDisplayClassesByWeek(week: number): classAttribute[] {
    return this.displayIndex.get(week) || [];
  }


  /**
   * 获取默认展示的指定周和天的课程
   * @param week 周数
   * @param day 星期几
   * @param needSort 是否需要按照上课开始时间排序（默认不需要）
   * @returns 课程列表
   */
  getDefaultClassByDay(week: number, day: number, needSort: boolean = false): classAttribute[] {
    if (!needSort)
      return this.defaultIndex.get(week)?.get(day) || [];
    const unsorted: classAttribute[] = this.defaultIndex.get(week)?.get(day) || [];
    unsorted.sort((a, b) => a.timeSpan[0] - b.timeSpan[0]);
    return unsorted;
  }


  /**
   * 创建新学期
   * @param name 学期名称
   * @param source 来源
   * @param beginTime 开始时间戳
   * @param createTime 创建时间戳
   * @param totWeekNum 总周数
   * @param timetable 课程表
   * @returns undefined，但如果发生错误则返回错误信息的字符串
   */
  newSemester(name: string, source: string, beginTime: number, createTime: number, totWeekNum: number = 0, timetable: classAttribute[] = []): string | undefined {
    try {
      if (timetable) {
        totWeekNum = this.getLatestWeek(timetable);
      }
      const semesterConfig: semesterAttribute = {
        name: name,
        source: source,
        createTime: createTime,
        beginTime: beginTime,
        totalWeekNum: totWeekNum
      };
      this.semesters.push(semesterConfig);
      ScheduleStorage.setSemesters(this.semesters);
      ScheduleStorage.setCourses(createTime, timetable);
      return;
    } catch(err) {
      return JSON.stringify(err);
    }
  }


  /**
   * 覆盖或合并指定学期的课程数据。会保留原有的颜色和优先级
   * @param id 学期索引
   * @param newSchedule 新课程列表
   * @param insertMode 0：覆盖，1：覆盖出现过的同名课程，2：追加
   * @returns undefined，但如果发生错误则返回错误信息的字符串
   */
  coverExistSemester(id: number, newSchedule: classAttribute[], insertMode: COVER_MODE, fillAll: boolean = false): string | undefined {
    try {
      const originSchedule: classAttribute[] = ScheduleStorage.getCourses(this.semesters[id].createTime);

      if (fillAll) {
        const nameToColor: Map<string, string> = new Map<string, string>();
        const nameToPriority: Map<string, number> = new Map<string, number>();
        let randomColor: number = getRandomInt(0, colorSetLen - 1);
        for (const originClass of originSchedule) {
          if (!nameToColor.has(originClass.name)) {
            nameToColor.set(originClass.name, originClass.color);
            nameToPriority.set(originClass.name, originClass.priority);
          }
        }
        for (const newClass of newSchedule) {
          if (nameToPriority.has(newClass.name)) {
            newClass.priority = nameToPriority.get(newClass.name)!;
          } else {
            newClass.priority = 5;
          }
          if (nameToColor.has(newClass.name)) {
            newClass.color = nameToColor.get(newClass.name)!;
          } else {
            newClass.color = colorSet[randomColor];
            nameToColor.set(newClass.name, colorSet[randomColor]);
            randomColor = (randomColor + 1) % colorSetLen;
          }
        }
      }

      if (insertMode === COVER_MODE.APPEND) {
        const newLength: number = newSchedule.length;
        for (const originClass of originSchedule) {
          // 检查是否已存在相同的课程
          let exists: boolean = false;
          for (let i = 0; i < newLength; i++)
            if (areClassAttributesEqual(originClass, newSchedule[i], false)) {
              exists = true;
              break;
            }
          if (!exists) {
            newSchedule.push(originClass);
          }
        }
      } else if (insertMode === COVER_MODE.COVER_DUPLICATE) { // 覆盖出现过的课程
        const newLength: number = newSchedule.length;
        let flag: boolean;
        originSchedule.forEach(originClass => {
          flag = true;
          for (let i = 0; i < newLength; i++)
            if (newSchedule[i].name === originClass.name) {
              flag = false;
              break;
            }
          if (flag)
            newSchedule.push(originClass);
        })
      }

      ScheduleStorage.setCourses(this.semesters[id].createTime, newSchedule);
      let latestWeek: number = this.getLatestWeek(newSchedule);
      if (latestWeek !== this.semesters[id].totalWeekNum) {
        this.semesters[id].totalWeekNum = latestWeek;
        ScheduleStorage.setSemesters(this.semesters);
      }
      let err: string | undefined;
      if (id === this.displaySemester)
        err = this.rebuildDisplayIndex(newSchedule);
      if (id === this.defaultSemester)
        err = this.rebuildDefaultIndex(newSchedule) || err;
      return err;
    } catch(err) {
      return JSON.stringify(err);
    }
  }


  /**
   * 临时切换课表，用于在功能页查看
   * @param target 目标学期索引
   * @returns undefined，但如果发生错误则返回错误信息的字符串
   */
  switchTempSemester(target: number): string | undefined {
    try {
      this.displaySemester = target;
      this.rebuildDisplayIndex(ScheduleStorage.getCourses(this.semesters[target].createTime));
      return;
    } catch(err) {
      return JSON.stringify(err);
    }
  }


  /**
   * 初始化或切换默认课表，将会用于首页、添加日程以及桌面卡片
   * @param target 目标学期索引
   * @returns undefined，但如果发生错误则返回错误信息的字符串
   */
  setDefaultSemester(target: number): string | undefined {
    try {
      ScheduleStorage.setDefaultSemester(target);
      this.defaultSemester = target;
      return this.rebuildDefaultIndex(ScheduleStorage.getCourses(this.semesters[target].createTime));
    } catch(err) {
      return JSON.stringify(err);
    }
  }


  /**
   * 获取课程列表中的最大周数
   * @param timetable 课程列表
   * @returns 最大周数（数字），如果发生错误则返回0
   */
  getLatestWeek(timetable: classAttribute[]): number {
    try {
      let latestWeek: number = 0;
      timetable.forEach(singleClass => {
        latestWeek = Math.max(latestWeek, singleClass.weekOfTerm[singleClass.weekOfTerm.length - 1]);
      });
      return latestWeek;
    } catch(err) {
      return 0;
    }
  }


  /**
   * 向指定学期添加一门课程
   * @param id 学期索引
   * @param newClass 新课程
   * @returns undefined，但如果发生错误则返回错误信息的字符串
   */
  addClassToSemester(id: number, newClass: classAttribute, changeAllColor: boolean = false): string | undefined {
    try {
      const originClass: classAttribute[] = ScheduleStorage.getCourses(this.semesters[id].createTime);
      if (changeAllColor) {
        originClass.forEach(singleClass => {
          if (singleClass.name === newClass.name)
            singleClass.color = newClass.color;
        });
      }
      originClass.push(newClass);
      return this.coverExistSemester(id, originClass, COVER_MODE.COVER);
    } catch(err) {
      return JSON.stringify(err);
    }
  }


  /**
   * 向指定学期删除一门课程
   * @param id 学期索引
   * @param removingClass 新课程
   * @returns 删除成功无返回值，如果未找到课程则返回'NotFound'，如果发生错误则返回错误信息的字符串
   */
  deleteClassFromSemester(id: number, removingClass: classAttribute): string | undefined {
    try {
      const originClass: classAttribute[] = ScheduleStorage.getCourses(this.semesters[id].createTime);
      let hasEqualClass: boolean = false;
      for (let i = originClass.length - 1; i >= 0; i--)
        if (areClassAttributesEqual(originClass[i], removingClass)) {
          originClass.splice(i, 1);
          hasEqualClass = true;
          break;
        }
      if (hasEqualClass)
        return this.coverExistSemester(id, originClass, COVER_MODE.COVER);
    } catch(err) {
      return JSON.stringify(err);
    }
    return 'NotFound';
  }


  /**
   * 修改指定学期的开始时间
   * @param id 要修改的学期编号
   * @param newStartTime 新的学期开始时间（毫秒级时间戳）
   * @returns 无异常时返回undefined，发生异常时返回异常信息的JSON字符串
   */
  changeSemesterStartTime(id: number, newStartTime: number): string | undefined {
    try {
      this.semesters[id].beginTime = newStartTime;
      ScheduleStorage.setSemesters(this.semesters);
      return;
    } catch(err) {
      return JSON.stringify(err);
    }
  }


  /**
   * 删除指定编号的学期
   * @param id 要删除的学期编号
   * @returns 若删除的是当前显示/默认学期返回'Occupied'；无异常返回undefined；异常返回异常信息的JSON字符串
   */
  deleteSemester(id: number): string | undefined {
    try {
      if (id === this.displaySemester || id === this.defaultSemester)
        return 'Occupied';
      ScheduleStorage.deleteSemesterData(this.semesters[id].createTime);
      if (this.displaySemester > id)
        this.displaySemester--;
      if (this.defaultSemester > id) {
        this.defaultSemester--;
        ScheduleStorage.setDefaultSemester(this.defaultSemester);
      }
      this.semesters.splice(id, 1);
      ScheduleStorage.setSemesters(this.semesters);
      return;
    } catch(err) {
      return JSON.stringify(err);
    }
  }


  /**
   * 重命名指定编号的学期
   * @param id 要重命名的学期编号
   * @param newName 学期的新名称
   * @returns 无异常时返回undefined，发生异常时返回异常信息的JSON字符串
   */
  renameSemester(id: number, newName: string): string | undefined {
    try {
      this.semesters[id].name = newName;
      ScheduleStorage.setSemesters(this.semesters);
      return;
    } catch(err) {
      return JSON.stringify(err);
    }
  }


  /**
   * 解析在线课程表数据，将多层嵌套的课程数据扁平化
   * @param originData 原始的三层嵌套课程数据结构 [][][]
   * @param fillAll 是否补充颜色和优先级属性
   * @returns 扁平化后的课程属性数组，已处理在线课表缺失或待处理的课程ID、学分、优先级、颜色等信息
   */
  parseOnlineSchedule(originData: classAttribute[][][], fillAll: boolean = false): classAttribute[] {
    const parsedData: classAttribute[] = [];
    if (fillAll) {
      const nameToColor: Map<string, number> = new Map<string, number>();
      let randomColor: number = getRandomInt(0, colorSetLen - 1);
      originData.forEach(layer1 => {
        layer1?.forEach(layer2 => {
          layer2?.forEach(layer3 => {
            if (layer3) {
              let sep: string[] = extractCredits(layer3.id);
              layer3.dayOfWeek = (layer3.dayOfWeek + 1) % 7;
              layer3.id = sep[0];
              layer3.credits = sep[1];
              layer3.priority = 5;
              if (nameToColor.has(layer3.name))
                layer3.color = colorSet[nameToColor.get(layer3.name)!];
              else {
                layer3.color = colorSet[randomColor];
                nameToColor.set(layer3.name, randomColor);
                randomColor = (randomColor + 1) % colorSetLen;
              }
              parsedData.push(layer3);
            }
          });
        });
      });
    } else {
      originData.forEach(layer1 => {
        layer1?.forEach(layer2 => {
          layer2?.forEach(layer3 => {
            if (layer3) {
              let sep: string[] = extractCredits(layer3.id);
              layer3.dayOfWeek = (layer3.dayOfWeek + 1) % 7;
              layer3.id = sep[0];
              layer3.credits = sep[1];
              parsedData.push(layer3);
            }
          });
        });
      });
    }
    return parsedData;
  }

  toppingSemester(target: number): string | undefined {
    try {
      if (this.displaySemester === target)
        this.displaySemester = 0;
      else if (this.displaySemester < target)
        this.displaySemester++;
      if (this.defaultSemester === target)
        this.defaultSemester = 0;
      else if (this.defaultSemester < target)
        this.defaultSemester++;

      const targetSemester: semesterAttribute = this.semesters[target];
      for (let i = target; i > 0; i--) {
        this.semesters[i] = this.semesters[i - 1];
      }
      this.semesters[0] = targetSemester;
      ScheduleStorage.setSemesters(this.semesters);
      ScheduleStorage.setDefaultSemester(this.defaultSemester); // 不需要rebuildIndex（内容不变），因此不调用this.setDefaultSemester()
      return;
    } catch(err) {
      return JSON.stringify(err);
    }
  }
}

export default new ScheduleManager();