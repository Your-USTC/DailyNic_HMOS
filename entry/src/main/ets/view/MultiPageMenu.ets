import { GridData, MultiLink } from "../constants/Links"
import { LINK } from "../constants/Links"
import PageRouter from "../utils/PageRouter"

export let webName: ResourceStr[] = [];

export function resetWebName(title?: ResourceStr) {
  if (title)
    webName = [title];
  else
    webName = [];
}

@Builder function singleGridItem(pageInfo: NavPathStack, linkName: ResourceStr[], groupIndex: number) {
  Menu() {
    ForEach(linkName, (item: ResourceStr, index: number) => {
      MenuItem({ content: item })
        .onClick(() => {
          const paramData = LINK[groupIndex].set[index];
          webName.push(paramData?.title ?? 'blank');
          pageInfo.pushPath({ name: "Webview", param: paramData });
        })
    })
  }
}

@Builder function singleSection(pageInfo: NavPathStack) {
  Menu() {
    MenuItem({ content: '同时打开过多网页\n会占用大量内存', startIcon: $r('app.media.exclamationmark_circle') })
      .contentFont({ size: 14 })
      .hitTestBehavior(HitTestMode.None)
    ForEach(LINK, (item: MultiLink[], index: number) => {
      MenuItem({
        content: item.,
        builder: singleGridItem(pageInfo, item.gridItemList, index),
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