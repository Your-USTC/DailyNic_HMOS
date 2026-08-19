import { hilog } from "@kit.PerformanceAnalysisKit";
import { webview } from "@kit.ArkWeb";
import { rcp } from "@kit.RemoteCommunicationKit";

export const COOKIE_REPO_ID = "NicDefault";
export const SESSION = rcp.createSession({
  cookieRepository: rcp.CookieRepository.create(COOKIE_REPO_ID),
  requestConfiguration: {
    transfer: { autoRedirect: true },
  },
});

export abstract class Client {
  protected client?: rcp.Session;
  protected initialized?: Promise<boolean>;

  public constructor() {}

  public destroy() {
    this.client?.close();
    this.client = undefined;
    this.initialized = undefined;
  }

  public init(): Promise<boolean> {
    if(this.initialized === undefined) {
      this.initialized = this.tryInit();
    }
    return this.initialized;
  }

  protected abstract tryInit(): Promise<boolean>;
}

export async function fetchCookie(domain: number) {
  webview.WebCookieManager.saveCookieSync();
  try {
    const cookies = new Array<rcp.ResponseCookie>();
    getCookie(domain, "id.ustc.edu.cn", "/", cookies);
    getCookie(domain, "id.ustc.edu.cn", "/cas/", cookies);
    getCookie(domain, "id.ustc.edu.cn", "/gate/", cookies);
    await rcp.CookieRepository.create(COOKIE_REPO_ID)
      .setCookies(cookies);
  } catch(e) {
    hilog.fatal(domain, "fetchCookie", `${e.name}: ${e.message}\n${e.stack}`);
  }
}

function getCookie(domain: number, url: string, path: string, cookies: rcp.ResponseCookie[]) {
  try {
    for(const c of webview.WebCookieManager.fetchCookieSync(`https://${url}${path}`).split("; ")) {
      const index = c.indexOf("=");
      const name = c.substring(0, index);
      if(!cookies.some(c => c.domain === url && c.name === name && c.path === "/" )) {
        cookies.push({
          name: name,
          value: c.substring(index + 1),
          domain: url,
          path: path,
        });
      }
    }
  } catch(e) {
    hilog.fatal(domain, "convertCookie", `${e.name}: ${e.message}\n${e.stack}`);
  }
}