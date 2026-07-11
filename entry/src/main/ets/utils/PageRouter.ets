import { SimpleLink, LinkAddress, MultiLink } from "../constants/Links";
import { resetWebName } from "../view/MultiPageMenu";
import { recordClick, refreshFunc } from './FunctionOrder';

function pushNewPage(pageName: string, pageInfo: NavPathStack) {
  pageInfo.popToName(pageName);
  pageInfo.pushPath({ name: pageName });
}

function pushNewUrl(title: ResourceStr, url: string | Resource, pageInfo: NavPathStack) {
  pageInfo.clear();
  pageInfo.pushPath({ name: "Webview", param: { title: title, url: url } as SimpleLink})
}


@CustomDialog struct linkPickerDialog {
  controller: CustomDialogController;
  title: ResourceStr = '';
  subLinks: LinkAddress[] = [];
  pageInfo: NavPathStack = new NavPathStack();
  build() {
    Column() {
      Row() {
        Text(this.title)
        Button({ buttonStyle: ButtonStyleMode.NORMAL, type: ButtonType.Circle }) {
          SymbolGlyph($r('app.media.close'))
            .fontSize(20)
        }
        .width(36)
        .height(36)
        .onClick(() => {
          this.controller.close();
        })
      }
      .width('100%')

      ForEach(this.subLinks, (item: LinkAddress, index: number) => {
        Text(item.subtitle)
          .onClick(() => {
            if (item.notUrl) {
              pushNewPage(item.url as string, this.pageInfo);
            } else {
              pushNewUrl(this.title, item.url, this.pageInfo);
            }
          })
      })
    }
    .width('100%')
  }
}


class PageRouter {
  linkPicker: CustomDialogController | null = null;

  openMultiLink(linkDetail: MultiLink, pageInfo: NavPathStack, linkGroup1?: number, linkGroup2?: number) {
    if (linkGroup1 && linkGroup2) {
      // webName.push(LINK.get(preName)?.title ?? 'blank');
      resetWebName(linkDetail.title);
      // 记录并刷新点击次数
      recordClick(linkGroup1, linkGroup2);
      refreshFunc();
    }

    // 打开对应页面
    if (linkDetail.url.length === 1) {
      if (linkDetail.url[0].notUrl) {
        pushNewPage(linkDetail.url[0].url as string, pageInfo);
      } else {
        pushNewUrl(linkDetail.title, linkDetail.url[0].url, pageInfo);
      }
    } else {
      this.linkPicker = new CustomDialogController({
        builder: linkPickerDialog({
          title: linkDetail.title,
          subLinks: linkDetail.url
        }),
        autoCancel: true,
        gridCount: 4
      });
      this.linkPicker.open();
    }
  }
}

export default new PageRouter();