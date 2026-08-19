import { relationalStore, ValuesBucket } from "@kit.ArkData";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { LessonInfo, SemesterInfo } from "../ScheduleData";
import dayjs from "dayjs";
import { jwClient } from "../clients/JWClient";
import { colorSet, colorSetLen, getRandomInt } from "../tools";

const DOMAIN = 0x0020;
const enum Version {
  V0, // 尚未创建
  V1
};
const CURR_VERSION = Version.V1;
const STORE_CONFIG: relationalStore.StoreConfig = {
  name: "nic-schedule.db",
  securityLevel: relationalStore.SecurityLevel.S1,
};
const CREATE_SEMESTER_TABLE = `CREATE TABLE IF NOT EXISTS semesters (
  id INTEGER PRIMARY KEY,
  nameZh TEXT NOT NULL,
  start INTEGER NOT NULL,
  end INTEGER NOT NULL
)`;
const CREATE_SEMESTER_INDEX = `
  CREATE INDEX IF NOT EXISTS idx_time ON semesters(start ASC, end DESC)
`;
const CREATE_LESSON_TABLE = `CREATE TABLE IF NOT EXISTS lesson (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  semester INTEGER NOT NULL,
  lessonId INTEGER NOT NULL,
  lessonCode TEXT NOT NULL,
  courseName TEXT NOT NULL,
  weekday INTEGER NOT NULL, -- CHECK (weekday BETWEEN 1 AND 7)
  start INTEGER NOT NULL,
  end INTEGER NOT NULL,
  teachers TEXT NOT NULL, -- 授课教师列表由换行符分隔
  place TEXT NOT NULL,
  week INTEGER NOT NULL,
  UNIQUE(semester, lessonId, weekday, start, end, week),
  FOREIGN KEY (semester) REFERENCES semesters (id) ON DELETE CASCADE,
  FOREIGN KEY (semester, week) REFERENCES flag (semester, week) ON DELETE CASCADE
)`;
const CREATE_FLAG_TABLE = `CREATE TABLE IF NOT EXISTS flag (
  semester INTEGER NOT NULL,
  week INTEGER NOT NULL,
  PRIMARY KEY (semester, week),
  FOREIGN KEY (semester) REFERENCES semesters (id) ON DELETE CASCADE
)`
const CREATE_COLOR_TABLE = `CREATE TABLE IF NOT EXISTS color (
  semester INTEGER NOT NULL,
  lessonId INTEGER NOT NULL,
  color TEXT NOT NULL,
  PRIMARY KEY (semester, lessonId),
  FOREIGN KEY (semester) REFERENCES semesters (id) ON DELETE CASCADE
)`

class ScheduleManager {
  private store?: relationalStore.RdbStore;
  private initialized?: Promise<boolean>;

  public async deinit() {
    try {
      await this.store?.close();
      this.store = undefined;
      hilog.debug(DOMAIN, "closeScheduleManager", "已关闭数据库");
    } catch(e) {
      hilog.fatal(DOMAIN, "closeScheduleManager", `${e.name}: ${e.message}\n${e.stack}`);
    }
  }

  public init(ctx: Context) {
    this.initialized = this.tryInit(ctx);
  }

  private async tryInit(ctx: Context) {
    // 获得数据库实例
    try {
      this.store = await relationalStore.getRdbStore(ctx, STORE_CONFIG);
    } catch(e) {
      hilog.fatal(DOMAIN, "initScheduleManager", `${e.name}: ${e.message}\n${e.stack}`);
      return false;
    }
    hilog.info(DOMAIN, "initScheduleManager", `成功，数据库版本为${this.store.version}`);

    // 更新数据库
    let tx: relationalStore.Transaction | undefined;
    try {
      tx = await this.store.createTransaction({});
      if(this.store.version == Version.V0) {
        await tx.execute(CREATE_SEMESTER_TABLE);
        await tx.execute(CREATE_SEMESTER_INDEX);
        await tx.execute(CREATE_LESSON_TABLE);
        await tx.execute(CREATE_FLAG_TABLE);
        await tx.execute(CREATE_COLOR_TABLE);
        await tx.commit();
        this.store.version = CURR_VERSION;
        hilog.info(DOMAIN, "updateSchedule", "已建表");
      } else if(this.store.version < CURR_VERSION) {
        // TODO: 数据库更新逻辑
        await tx.commit();
      }
    } catch(e) {
      hilog.fatal(DOMAIN, "updateSchedule", `${e.name}: ${e.message}\n${e.stack}`);
      await tx?.rollback();
      return false;
    }

    return true;
  }

  public async updateSemester(semesters: SemesterInfo[]) {
    const init = await this.initialized;
    if(!init) {
      hilog.error(DOMAIN, "updateSemester", "数据库初始化失败");
      return;
    }

    const values = semesters.map(s => {
      return {
        "id": s.id,
        "nameZh": s.nameZh,
        "start": dayjs.utc(s.start).valueOf(),
        "end": dayjs.utc(s.end).valueOf(),
      } as ValuesBucket;
    });

    let tx: relationalStore.Transaction | undefined;
    try {
      tx = await this.store!.createTransaction({});
      await tx.batchInsertWithConflictResolution("semesters", values, relationalStore.ConflictResolution.ON_CONFLICT_IGNORE);
      await tx.commit();
    } catch(e) {
      hilog.fatal(DOMAIN, "updateSemester", `${e.name}: ${e.message}\n${e.stack}`);
      await tx?.rollback();
      return;
    }
    hilog.debug(DOMAIN, "updateSemester", "已存储学期数据");
  }

  public async getSemester(id?: number, name?: string): Promise<SemesterInfo | undefined> {
    const init = await this.initialized;
    if(!init) {
      hilog.error(DOMAIN, "getSemester", "数据库初始化失败");
      return undefined;
    }
    if(id === undefined && name === undefined) {
      hilog.error(DOMAIN, "getSemester", "参数不能均为undefined");
      return undefined;
    }

    let resultSet: relationalStore.ResultSet | undefined;
    try {
      const predicate = new relationalStore.RdbPredicates("semesters");
      if(id !== undefined) {
        predicate.equalTo("id", id);
      } else {
        predicate.equalTo("nameZh", name);
      }
      resultSet = await this.store!.query(predicate);

      while(resultSet.goToNextRow()) {
        return {
          id: resultSet.getLong(0),
          nameZh: resultSet.getString(1),
          start: dayjs(resultSet.getLong(2)).utc().format("YYYY-MM-DD"),
          end: dayjs(resultSet.getLong(3)).utc().format("YYYY-MM-DD"),
        } as SemesterInfo;
      }
      return undefined;
    } catch(e) {
      hilog.fatal(DOMAIN, "getSemester", `${e.name}: ${e.message}\n${e.stack}`);
      return undefined;
    } finally {
      resultSet?.close();
    }
  }

  public async getSemesters(): Promise<SemesterInfo[]> {
    const init = await this.initialized;
    if(!init) {
      hilog.error(DOMAIN, "getSemesters", "数据库初始化失败");
      return [];
    }

    let resultSet: relationalStore.ResultSet | undefined;
    try {
      const predicate = new relationalStore.RdbPredicates("semesters");
      resultSet = await this.store!.query(predicate);

      const res: SemesterInfo[] = [];
      while(resultSet.goToNextRow()) {
        res.push({
          id: resultSet.getLong(0),
          nameZh: resultSet.getString(1),
          start: dayjs(resultSet.getLong(2)).utc().format("YYYY-MM-DD"),
          end: dayjs(resultSet.getLong(3)).utc().format("YYYY-MM-DD"),
        })
      }
      return res;
    } catch(e) {
      hilog.fatal(DOMAIN, "getSemesters", `${e.name}: ${e.message}\n${e.stack}`);
      return [];
    } finally {
      resultSet?.close();
    }
  }

  public async getStoredSemesters(): Promise<SemesterInfo[]> {
    const init = await this.initialized;
    if(!init) {
      hilog.error(DOMAIN, "getStoredSemesters", "数据库初始化失败");
      return [];
    }

    let resultSet: relationalStore.ResultSet | undefined;
    let semesterRes: relationalStore.ResultSet | undefined;
    try {
      const predicate = new relationalStore.RdbPredicates("flag")
        .distinct();
      resultSet = await this.store!.query(predicate, ["semester"]);

      const res: SemesterInfo[] = [];
      while(resultSet.goToNextRow()) {
        const id = resultSet.getLong(0);
        const pred = new relationalStore.RdbPredicates("semesters")
          .equalTo("id", id);
        semesterRes = await this.store!.query(pred);
        if(semesterRes.goToNextRow()) {
          res.push({
            id: semesterRes.getLong(0),
            nameZh: semesterRes.getString(1),
            start: dayjs(semesterRes.getLong(2)).utc().format("YYYY-MM-DD"),
            end: dayjs(semesterRes.getLong(3)).utc().format("YYYY-MM-DD"),
          })
        }
        semesterRes.close();
      }
      return res;
    } catch(e) {
      hilog.fatal(DOMAIN, "getStoredSemesters", `${e.name}: ${e.message}\n${e.stack}`);
      return [];
    } finally {
      resultSet?.close();
      semesterRes?.close();
    }
  }

  public async deleteSchedule(semester: number) {
    const init = await this.initialized;
    if(!init) {
      hilog.error(DOMAIN, "deleteSchedule", "数据库初始化失败");
      return;
    }

    let tx: relationalStore.Transaction | undefined;
    try {
      tx = await this.store!.createTransaction({});
      await tx.delete(
        new relationalStore.RdbPredicates("lesson")
          .equalTo("semester", semester)
      );
      await tx.delete(
        new relationalStore.RdbPredicates("flag")
          .equalTo("semester", semester)
      );
      await tx.delete(
        new relationalStore.RdbPredicates("color")
          .equalTo("semester", semester)
      );
      await tx.commit();
    } catch(e) {
      hilog.fatal(DOMAIN, "deleteSchedule", `${e.name}: ${e.message}\n${e.stack}`);
      await tx?.rollback();
      return;
    }
    hilog.debug(DOMAIN, "deleteSchedule", "已删除课程数据");
  }

  public async updateSchedule(semester: number, lessons: LessonInfo[], week: number) {
    const init = await this.initialized;
    if(!init) {
      hilog.error(DOMAIN, "updateSchedule", "数据库初始化失败");
      return;
    }

    const valLesson = lessons.map(l => {
        return {
          "semester": semester,
          "lessonId": l.lessonId,
          "lessonCode": l.lessonCode,
          "courseName": l.courseName,
          "weekday": l.weekday,
          "start": l.start,
          "end": l.end,
          "teachers": l.teachers.join("\n"),
          "place": l.place,
          "week": week,
        } as ValuesBucket;
      });

    let tx: relationalStore.Transaction | undefined;
    try {
      tx = await this.store!.createTransaction({});
      if(valLesson.length > 0) {
        // 存储课程数据
        await tx.batchInsert("lesson", valLesson);

        // 分配颜色
        let i = getRandomInt(0, colorSetLen - 1);
        const valColor = Array.from(new Set(lessons.map(l => l.lessonId)).values())
          .map((l, index) => {
            return {
              "semester": semester,
              "lessonId": l,
              "color": colorSet[(i + index) % colorSetLen],
            } as ValuesBucket;
          });
        await tx.batchInsertWithConflictResolution("color", valColor, relationalStore.ConflictResolution.ON_CONFLICT_IGNORE);
      }
      await tx.insert("flag", { "semester": semester, "week": week });
      await tx.commit();
    } catch(e) {
      hilog.fatal(DOMAIN, "updateSchedule", `${e.name}: ${e.message}\n${e.stack}`);
      await tx?.rollback();
      return;
    }
    hilog.debug(DOMAIN, "updateSchedule", "已存储课程数据");
  }

  public async getSchedule(semester: number, week: number): Promise<LessonInfo[]> {
    const init = await this.initialized;
    if(!init) {
      hilog.error(DOMAIN, "getSchedule", "数据库初始化失败");
      return [];
    }

    let res: LessonInfo[] | undefined;
    if(!(await this.getFlag(semester, week))) {
      res = await jwClient.getSchedule(semester, week);
      await this.updateSchedule(semester, res, week);
    }

    let resultSet: relationalStore.ResultSet | undefined;
    try {
      // 获取颜色
      const predColor = new relationalStore.RdbPredicates("color")
        .equalTo("semester", semester);
      resultSet = await this.store!.query(predColor, ["lessonId", "color"]);
      const colors: Record<number, string> = {};
      while(resultSet.goToNextRow()) {
        colors[resultSet.getLong(0)] = resultSet.getString(1);
      }

      if(res === undefined) {
        // 获取课程
        const predLesson = new relationalStore.RdbPredicates("lesson")
          .equalTo("semester", semester)
          .and().equalTo("week", week);
        resultSet = await this.store!.query(predLesson);

        res = [];
        while(resultSet.goToNextRow()) {
          const lessonId = resultSet.getLong(2);
          res.push({
            lessonId: lessonId,
            lessonCode: resultSet.getString(3),
            courseName: resultSet.getString(4),
            weekday: resultSet.getLong(5),
            start: resultSet.getLong(6),
            end: resultSet.getLong(7),
            teachers: resultSet.getString(8).split("\n"),
            place: resultSet.getString(9),
            color: colors[lessonId],
          });
        }
      } else {
        for(const l of res) {
          l.color = colors[l.lessonId];
        }
      }
      return res;
    } catch(e) {
      hilog.fatal(DOMAIN, "getSchedule", `${e.name}: ${e.message}\n${e.stack}`);
      return [];
    } finally {
      resultSet?.close();
    }
  }

  private async getFlag(semester: number, week: number): Promise<boolean> {
    const init = await this.initialized;
    if(!init) {
      hilog.error(DOMAIN, "getFlag", "数据库初始化失败");
      return false;
    }

    let resultSet: relationalStore.ResultSet | undefined;
    try {
      const predicate = new relationalStore.RdbPredicates("flag")
        .equalTo("semester", semester)
        .and().equalTo("week", week);
      resultSet = await this.store!.query(predicate);
      return resultSet.goToNextRow();
    } catch(e) {
      hilog.fatal(DOMAIN, "getFlag", `${e.name}: ${e.message}\n${e.stack}`);
      return false;
    } finally {
      resultSet?.close();
    }
  }
}

export let scheduleManager = new ScheduleManager();