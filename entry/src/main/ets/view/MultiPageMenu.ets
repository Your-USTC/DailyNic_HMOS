import { LinkAddress, LinkSet, MultiLink, SimpleLink } from "../constants/Links"
import { LINK } from "../constants/Links"

export let webName: ResourceStr[] = [];

export function resetWebName(title?: ResourceStr) {
  if (title)
    webName = [title];
  else
    webName = [];
}

@Builder function multiUrl(pageInfo: NavPathStack, urls: LinkAddress[], title: ResourceStr) {
  Menu() {
    ForEach(urls, (item: LinkAddress, index: number) => {
      MenuItem({ content: item.subtitle })
        .onClick(() => {
          webName.push(title);
          if (item.notUrl) {
            pageInfo.pushPath({ name: item.url as string });
          } else {
            pageInfo.pushPath({ name: "Webview", param: { title: title, url: item.url } as SimpleLink })
          }
        })
    })
  }
}

@Builder function singleGridItem(pageInfo: NavPathStack, elements: MultiLink[]) {
  Menu() {
    ForEach(elements, (item: MultiLink, index: number) => {
      if (item.url.length === 1) {
        MenuItem({ content: item.title })
          .onClick(() => {
            webName.push(item.title);
            if (item.url[0].notUrl) {
              pageInfo.pushPath({ name: item.url[0].url as string });
            } else {
              pageInfo.pushPath({ name: "Webview", param: { title: item.title, url: item.url[0].url } as SimpleLink })
            }
          })
      } else {
        MenuItem({ content: item.title, builder: multiUrl(pageInfo, item.url, item.title), endIcon: $r('sys.media.ohos_ic_public_arrow_right') })
      }
    })
  }
}

@Builder function singleSection(pageInfo: NavPathStack) {
  Menu() {
    MenuItem({ content: '同时打开过多网页\n会占用大量内存', startIcon: $r('app.media.exclamationmark_circle') })
      .contentFont({ size: 14 })
      .hitTestBehavior(HitTestMode.None)
    ForEach(LINK, (item: LinkSet, index: number) => {
      MenuItem({
        content: item.title,
        builder: singleGridItem(pageInfo, item.set),
        endIcon: $r('sys.media.ohos_ic_public_arrow_right')
      })
    })
  }
}

@Builder export function MultiPageMenu(pageInfo: NavPathStack) {
  Menu() {
    MenuItem({ content: '打开新网页', builder: singleSection(pageInfo), endIcon: $r('sys.media.ohos_ic_public_arrow_right') })
    ForEach(webName, (item: ResourceStr, index: number) => {
      if (index + 1 == webName.length) {
        MenuItem({ content: item, endIcon: $r('sys.media.ohos_ic_public_location') })
          .enabled(false)
      } else {
        MenuItem({ content: item })
          .onClick(() => {
            webName.push(webName.splice(index, 1)[0]);
            pageInfo.moveIndexToTop(pageInfo.size() - webName.length + index);
          })
      }
    })
  }
}