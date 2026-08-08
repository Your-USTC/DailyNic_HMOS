import BackgroundImage from '../../utils/BgImageManager';
import { answerStore } from '../../utils/MockPractice/AnswerSessionManager';
import { fullID, testAttribute } from '../../utils/MockPractice/constants';
import { importNewTest } from '../../utils/MockPractice/QuestionsManager';
import { getAllTest, removeTest } from '../../utils/MockPractice/TestManager';


@Builder
export function MPLBuilder(name: string, param?: Object) {
  MockPracticeList();
}

@Entry
@Component
struct MockPracticeList {
  @State practiceList: testAttribute[] = getAllTest();

  menuItems: Array<NavigationMenuItem> = [
    {
      value: 'delete',
      icon: $r('app.media.trash_red'),
      action: () => {
        const testList = getAllTest();
        if (testList.length > 0)
          removeTest(testList[0].uuid);
      }
    },
    {
      value: 'import',
      icon: $r('app.media.import'),
      action: () => {
        importNewTest("test", this.getUIContext())
          .then(() => {
            this.practiceList = getAllTest();
          });
      }
    }
  ];
  pathStack: NavPathStack = new NavPathStack();
  build() {
    NavDestination() {
      List() {
        ForEach(this.practiceList, (singlePractice: testAttribute, index: number) => {
          ListItem() {
            Column() {
              Text(singlePractice.name)
              Text(new Date(singlePractice.createTime).toLocaleString('zh-cn', { year: 'numeric', month: '2-digit', day: '2-digit' }))
              Text(new Date(singlePractice.lastOpenTime).toLocaleString('zh-cn', { year: 'numeric', month: '2-digit', day: '2-digit' }))
              Text("ID: " + singlePractice.uuid)
                .fontSize(12)
                .fontColor($r('app.color.transparent_text'))
            }
            .onClick(() => {
              const sessionId = answerStore.create(singlePractice.uuid, 'ordered', false);
              this.pathStack.pushPath({ name: "MockPracticeMain", param: { name: singlePractice.name, test: singlePractice.uuid, answer: sessionId } as fullID });
            })
          }
          .width('100%')
          .padding({ top: 10, bottom: 10, left: 16, right: 16 })
          .margin({ top: 8, bottom: 6 })
          .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
          .backgroundBlurStyle(BackgroundImage.blurLevel)
          .borderRadius(20)
        })
      }
      .width('100%')
      .height('100%')
      .alignListItem(ListItemAlign.Center)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .padding({ left: 12, right: 12 })
      .contentStartOffset(4)
      .contentEndOffset(12)
    }
    .title('自测', {
      backgroundBlurStyle: BackgroundImage.blurLevel,
      backgroundColor: BackgroundImage.blurLevel === undefined ? $r('app.color.shaded_background' + String(BackgroundImage.themeColor)) : undefined
    })
    .menus(this.menuItems)
    .backButtonIcon($r('app.media.close'))
    .backgroundColor(BackgroundImage.showImage ? '#00d00721' : $r('app.color.normal_background'))
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}