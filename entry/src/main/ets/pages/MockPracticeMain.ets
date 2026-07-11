import BackgroundImage from '../utils/BgImageManager';
import { testAttribute } from '../utils/MockPractice/constants';
import { importNewTest } from '../utils/MockPractice/QuestionsManager';
import { getAllTest } from '../utils/MockPractice/TestManager';


@Builder
export function MPMBuilder(name: string, param?: Object) {
  MockPracticeMain();
}

@Entry
@Component
struct MockPracticeMain {
  @State practiceList: testAttribute[] = getAllTest();
  canBeChosen: string[] = ['选项A', '选项B', '选项C', '选项D'];
  // questionDescription: string = 'simple';
  questionDescription: string = '123456';

  menuItems: Array<NavigationMenuItem> = [
    {
      value: 'list',
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
      Column() {
        Scroll() {
          Column() {
            Text() {
              Span('1/700  ')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
              Span(this.questionDescription)
            }
            .width('100%')
            .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
            .constraintSize({ minHeight: 60 })
            .padding(12)
            .borderRadius(20)
            Blank().layoutWeight(1)
          }
          .width('100%')
        }
        .width('calc(100% - 24vp)')
        .borderRadius(20)
        .margin({ top: 12, left: 12, right: 12 })
        .layoutWeight(1)

        List() {
          ForEach(this.canBeChosen, (optionContext: string, index: number) => {
            ListItem() {
              Row() {
                Text(String.fromCharCode(65 + index))
                  .fontWeight(FontWeight.Bold)
                  .margin({ left: 10, right: 10 })
                Text(optionContext)
                  .layoutWeight(1)
              }
              .constraintSize({ minHeight: 40 })
              .width('100%')
              .justifyContent(FlexAlign.Start)
            }
            .width('100%')
            .margin({ top: 8, bottom: 6 })
            .padding(4)
            .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
            .borderRadius(20)
          })
        }
        .padding({ left: 12, right: 12 })
        .width('100%')

        Row() {
          Button('上一题')
          Button('提交')
          Button('下一题')
        }
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .height('100%')
    }
    .title('近现代史纲要', {
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