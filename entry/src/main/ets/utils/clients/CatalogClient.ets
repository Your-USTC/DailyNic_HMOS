import { Client, COOKIE_REPO_ID } from "./utils";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { rcp } from "@kit.RemoteCommunicationKit";
import { SemesterInfo } from "../ScheduleData";
import { scheduleManager } from "../storage/ScheduleManager";

const DOMAIN = 0x0011;

class CatalogClient extends Client {
  protected override async tryInit(): Promise<boolean> {
    if(this.client === undefined) {
      this.client = rcp.createSession({
        baseAddress: "https://catalog.ustc.edu.cn",
        cookieRepository: rcp.CookieRepository.create(COOKIE_REPO_ID),
        requestConfiguration: {
          transfer: { autoRedirect: true }
        }
      });
    }

    try {
      let response = await this.client.get(
        "https://id.ustc.edu.cn/cas/login?service=https%3a%2f%2fcatalog.ustc.edu.cn%2fustc_cas_login%3fnext%3dhttps%253a%252f%252fcatalog.ustc.edu.cn%252fquery%252flesson"
      );
      if(!response.effectiveUrl?.toString().includes("/query/lesson")) {
        hilog.error(DOMAIN, "init", `登录失败，状态码：${response.statusCode}`);
        return false;
      }
      hilog.debug(DOMAIN, "init", "登录成功");
    } catch(e) {
      hilog.fatal(DOMAIN, "init", `${e.name}: ${e.message}\n${e.stack}`);
      return false;
    }
    return true;
  }

  public async getSemesters(remote: boolean = false): Promise<SemesterInfo[]> {
    const login = await this.init();
    if(login === false) {
      hilog.error(DOMAIN, "getSemesters", "登录失败");
      return [];
    }

    if(!remote) {
      const res = await scheduleManager.getSemesters();
      if(res.length > 0) {
        return res;
      }
    }

    try {
      const response = await this.client!.get("/api/teach/semester/list");
      const semesters = response.toJSON()! as SemesterInfo[];
      await scheduleManager.updateSemester(semesters);
      hilog.debug(DOMAIN, "getSemesters", "已从服务器获得学期数据");
      return semesters;
    } catch(e) {
      hilog.fatal(DOMAIN, "getSemesters", `${e.name}: ${e.message}\n${e.stack}`);
      return [];
    }
  }
}

export let catalogClient = new CatalogClient();