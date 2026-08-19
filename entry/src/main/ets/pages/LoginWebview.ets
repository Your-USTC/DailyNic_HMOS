import { webview } from "@kit.ArkWeb";

@Builder
export function loginViewBuilder(name: string, param: string[]) {
  LoginWebview()
}

// TODO 自动填写登录信息
@Component
struct LoginWebview {
  private controller = new webview.WebviewController();

  build() {
    NavDestination() {
      Web({
        src: "https://id.ustc.edu.cn/cas/login",
        controller: this.controller
      })
        .domStorageAccess(true)
        .javaScriptAccess(true)
        .width("100%")
        .height("100%")
        .onPageEnd(event => {
          if(event.url.includes("/gate/cas-success")) {
            this.queryNavigationInfo()?.pathStack.pop({} as PopInfo);
          }
        })
    }
  }
}