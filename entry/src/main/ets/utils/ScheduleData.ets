import { time2Seconds } from "./tools";

export interface LessonInfo {
  lessonId: number,
  lessonCode: string,
  courseName: string,
  weekday: number,
  start: number,
  end: number,
  teachers: string[],
  place: string,
  color?: string,
}

export interface RemoteLessonInfo {
  lessonId: number,
  lessonCode: string,
  courseName: string,
  weekday: number,
  startDate: string,
  endDate: string,
  teachers: string[],
  room?: string,
  building?: string,
  campus?: string,
  customPlace?: string,
}

export interface SemesterInfo {
  id: number,
  nameZh: string,
  start: string,
  end: string,
}

export interface TodayInfo {
  currentSemester: string,
  dayIndex: number,
  weekIndex: number,
  isInSemester: boolean,
}

export function convertLessonInfo(raw: RemoteLessonInfo): LessonInfo {
  return {
    lessonId: raw.lessonId,
    lessonCode: raw.lessonCode,
    courseName: raw.courseName,
    weekday: raw.weekday,
    start: time2Seconds(raw.startDate),
    end: time2Seconds(raw.endDate),
    teachers: raw.teachers,
    place: raw.room ?? raw.customPlace ?? "",
  } as LessonInfo;
}