import { Client, COOKIE_REPO_ID } from "./utils";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { rcp } from "@kit.RemoteCommunicationKit";
import { convertLessonInfo, LessonInfo, RemoteLessonInfo, SemesterInfo } from "../ScheduleData";
import { scheduleManager } from "../storage/ScheduleManager";

const DOMAIN = 0x0010;

class JWClient extends Client {
  private id?: number;

  protected override async tryInit(): Promise<boolean> {
    if(this.client === undefined) {
      this.client = rcp.createSession({
        baseAddress: "https://jw.ustc.edu.cn",
        cookieRepository: rcp.CookieRepository.create(COOKIE_REPO_ID),
        requestConfiguration: {
          transfer: { autoRedirect: true },
        }
      });
    }

    try {
      let response = await this.client.get("/ucas-sso/login");
      const loc = response.effectiveUrl?.toString();
      if(!loc?.includes("jw.ustc.edu.cn/home")) {
        hilog.error(DOMAIN, "init", `登录失败：${loc} (${response.statusCode})`);
        return false;
      }

      response = await this.client.get("/for-std/course-table");
      const u = response.headers["location"];
      const lastSegment = u?.substring(u.lastIndexOf("/") + 1) ?? "";
      const parsed = Number.parseInt(lastSegment);

      if(Number.isNaN(parsed)) {
        hilog.error(DOMAIN, "init", `未获得id，重定向后的地址：${u}`);
        return false;
      } else {
        this.id = parsed;
        hilog.debug(DOMAIN, "init", "登陆成功，已获得id：%{private}d", this.id);
      }
    } catch(e) {
      hilog.fatal(DOMAIN, "init", `${e.name}: ${e.message}\n${e.stack}`);
      return false;
    }
    return true;
  }

  public async getSchedule(semester: number, week: number): Promise<LessonInfo[]> {
    const login = await this.init();
    if(login === false) {
      hilog.error(DOMAIN, "getSchedule", "登录失败");
      return [];
    }

    try {
      const response = await this.client!.get(
        `/for-std/course-table/semester/${semester}/print-data/${this.id}?weekIndex=${week}`
      );
      const lessons = (((response.toJSON()! as ESObject).studentTableVm! as ESObject).activities! as RemoteLessonInfo[])
        .map(convertLessonInfo)
        .sort((a, b) => (a.weekday - b.weekday) || (a.start - b.start))
        .reduce((acc, l) => {
          // 合并相邻且相同的课程
          const p = acc.length > 0 ? acc[acc.length - 1] : undefined;
          // 间隔小于5分钟则认为是相邻的
          if(p?.weekday === l.weekday && p.lessonId === l.lessonId && l.start - p.end <= 300) {
            p.end = l.end;
          } else {
            acc.push(l);
          }
          return acc;
        }, [] as LessonInfo[]);
      return lessons;
    } catch(e) {
      hilog.fatal(DOMAIN, "getSchedule", `${e.name}: ${e.message}\n${e.stack}`);
      return [];
    }
  }

  public async inSemester(): Promise<SemesterInfo | undefined> {
    const login = await this.init();
    if(login === false) {
      hilog.error(DOMAIN, "inSemester", "登录失败");
      return undefined;
    }

    try {
      const info = (await this.client!.get("/home/get-current-teach-week"))
        .toJSON()!;
      if((info as ESObject).isInSemester as boolean) {
        return await scheduleManager.getSemester(undefined, (info as ESObject).currentSemester as string);
      }
      return undefined
    } catch(e) {
      hilog.fatal(DOMAIN, "getSchedule", `${e.name}: ${e.message}\n${e.stack}`);
      return undefined;
    }
  }
}

export let jwClient = new JWClient();
