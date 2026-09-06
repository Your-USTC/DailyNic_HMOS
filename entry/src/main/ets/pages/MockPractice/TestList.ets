import BackgroundImage from '../../utils/BgImageManager';
import { answerStore } from '../../utils/MockPractice/AnswerSessionManager';
import { fullID, testAttribute, csvImportConfig } from '../../utils/MockPractice/constants';
import { importTestFromCsv } from '../../utils/MockPractice/QuestionsManager';
import { readDataFromCsv } from '../../utils/MockPractice/DataTransformer';
import { getAllTest, removeTest } from '../../utils/MockPractice/TestManager';
import { hostContext } from '../../constants/BasicConstants';
import { CsvImportPanel } from './ImportPanel';


@Builder
export function MPLBuilder(name: string, param?: Object) {
  MockPracticeList();
}

@Entry
@Component
struct MockPracticeList {
  @State practiceList: testAttribute[] = getAllTest();
  @State showImportSheet: boolean = false;
  @State csvLines: string[] = [];
  @State csvFileName: string = 'test';

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
        this.startImport();
      }
    }
  ];
  pathStack: NavPathStack = new NavPathStack();

  startImport(): void {
    readDataFromCsv(hostContext()).then((file) => {
      if (file.lines.length === 0) {
        this.getUIContext().getPromptAction().showToast({ message: '未读取到 CSV 内容，导入已取消', duration: 2000 });
        return;
      }
      this.csvLines = file.lines;
      this.csvFileName = file.fileName;
      this.showImportSheet = true;
    });
  }

  confirmImport(name: string, config: csvImportConfig): void {
    const uuid = importTestFromCsv(name, this.csvLines, config);
    if (uuid === '') {
      this.getUIContext().getPromptAction().showToast({ message: '未能解析出题目，请检查起始行与列设置', duration: 2500 });
      return;
    }
    this.showImportSheet = false;
    this.practiceList = getAllTest();
    this.getUIContext().getPromptAction().showToast({ message: '导入成功', duration: 1500 });
  }

  @Builder
  importSheet() {
    CsvImportPanel({
      lines: this.csvLines,
      suggestedName: this.csvFileName,
      onConfirm: (name: string, config: csvImportConfig): void => {
        this.confirmImport(name, config);
      },
      onCancel: (): void => {
        this.showImportSheet = false;
      }
    })
  }

  build() {
    NavDestination() {
      Column() {
        if (this.practiceList.length === 0) {
          Column() {
            Column() {
              Stack() {
                Image($r('app.media.board'))
                  .width(100)
                  .interpolation(ImageInterpolation.Medium)
                  .draggable(false)
                Text('404')
                  .fontColor('#fff')
                  .offset({ x: -5, y: 26 })
              }
              Text('从右上角导入教师提供的 CSV\n文件以开始').fontSize(18).textAlign(TextAlign.Center);
            }
            .backgroundBlurStyle(BackgroundImage.blurLevel)
            .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.normal_background') : undefined)
            .padding({
              top: 5,
              left: 10,
              right: 10,
              bottom: 10
            })
            .borderRadius(12);
          }
          .height('80%')
          .justifyContent(FlexAlign.Center);
        } else {
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
                  this.pathStack.pushPath({
                    name: "MockPracticeMain",
                    param: { name: singlePractice.name, test: singlePractice.uuid, answer: sessionId } as fullID
                  });
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
      }
      .width('100%')
      .height('100%')
      .bindSheet($$this.showImportSheet, this.importSheet(), {
        detents: [SheetSize.MEDIUM, SheetSize.LARGE],
        preferType: SheetType.CENTER,
        showClose: false,
        scrollSizeMode: ScrollSizeMode.CONTINUOUS,
        backgroundColor: '#00d00721',
        blurStyle: BlurStyle.Regular,
        enableFloatingDragBar: true,
        title: { title: '导入自测卷', subtitle: '选择数据起始行并指定各列含义' }
      })
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
