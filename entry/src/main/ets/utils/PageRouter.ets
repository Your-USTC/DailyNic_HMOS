import { SimpleLink, LinkAddress, MultiLink, LINK } from "../constants/Links";
import { resetWebName } from "../view/MultiPageMenu";
import { gIndex_to_pic, recordClick, refreshFunc } from './FunctionOrder';

function pushNewPage(pageName: string, pageInfo: NavPathStack) {
  pageInfo.popToName(pageName);
  pageInfo.pushPath({ name: pageName });
}

function pushNewUrl(title: ResourceStr, url: string | Resource, pageInfo: NavPathStack) {
  pageInfo.clear();
  pageInfo.pushPath({ name: "Webview", param: { title: title, url: url } as SimpleLink})
}

export function pushRedirect(pageInfo: NavPathStack, item: LinkAddress, title?: ResourceStr) {
  if (item.notUrl) {
    pushNewPage(item.url as string, pageInfo);
  } else {
    pushNewUrl(title || 'untitled', item.url, pageInfo);
  }
}


@CustomDialog
export struct linkPickerDialog {
  controller: CustomDialogController;
  @Prop gridIndex: number = 0;
  @Prop index: number = 0;
  pageInfo: NavPathStack = new NavPathStack();
  build() {
    Column() {
      Row({ space: 5 }) {
        Image(gIndex_to_pic(this.gridIndex, this.index))
          .height(30)
          .margin({ right: 5 });

        Text(LINK[this.gridIndex].set[this.index].title)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });

        Button({ buttonStyle: ButtonStyleMode.NORMAL, type: ButtonType.Circle }) {
          Image($r('app.media.close'))
            .height(20)
            .width(20)
        }
        .width(36)
        .height(36)
        .onClick(() => {
          this.controller.close();
        })
      }
      .width('100%')
      .margin({ bottom: 5 })

      ForEach(LINK[this.gridIndex].set[this.index].url, (item: LinkAddress, index: number) => {
        Row() {
          Text(index.toString())
            .margin({ right: 6 })
            .fontWeight(FontWeight.Bold)
          Text(item.subtitle)
            .layoutWeight(1)
            .onClick(() => {
              pushRedirect(this.pageInfo, item, LINK[this.gridIndex].set[this.index].title as string);
              this.controller.close();
            })
        }
        .width('100%')
        .height(40)

        Divider()
      })
    }
    .padding(16)
    .width('100%')
  }
}