import { LinkSet, MultiLink } from "../constants/Links"
import { LINK } from "../constants/Links"
import { pushRedirect } from '../utils/PageRouter';

export let webName: ResourceStr[] = [];

export function resetWebName(title?: ResourceStr) {
  if (title)
    webName = [title];
  else
    webName = [];
}

@Builder function singleGridItem(pageInfo: NavPathStack, elements: MultiLink[], title: ResourceStr) {
  Menu() {
    ForEach(elements, (item: MultiLink, index: number) => {
      MenuItem({ content: item.title })
        .onClick(() => {
          pushRedirect(pageInfo, item.url[0], title);
        })
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
        builder: singleGridItem(pageInfo, item.set, item.title),
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