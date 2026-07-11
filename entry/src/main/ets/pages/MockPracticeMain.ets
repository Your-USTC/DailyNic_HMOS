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
  canBeChosen: string[] = ['选项A', '选项B', '选项C', '选项D 爱莉希雅 爱莉希雅 爱莉希雅 爱莉希雅 爱莉希雅 爱莉希雅'];
  // questionDescription: string = 'simple';
  questionDescription: string = '爱莉希雅是我的信念，爱莉希雅是我的答案！😫\n不是的！……爱莉希雅不一样……只有爱莉希雅不一样——！😡\n爱莉希雅……和任何人都不一样。😌\n因为爱莉希雅的名字……很好听。念起来就会让我很有安全感。那是这世上最圣洁的旋律……我不想省略。🤗\n爱莉希雅是地球真正的神明。祂选中了这颗星星，点燃深埋地底的火种，荒芜的星球就有了跳舞的心脏。🥰\n祂看护生命、守望文明。祂尽情爱着我们，真真诚诚地在这一切由祂庇护的事物面前袒露欢喜。🥵\n祂是空茫宇宙中最美好的神明。时间永远不能使祂枯萎，你们要与我一同记住祂的存在，不再忘记祂的名字。😄\n爱莉希雅是地球真正的神明。祂将真理与谦爱刻入心灵，于是蒙昧的生命从混沌中苏醒，人世传响祝福的弦音。😍\n祂庇护过往，包容彷徨。祂倾尽所有爱着我们，以高尚的栖祭护航正确的命途，又赐予你我祂的最大应许。😘\n祂是空茫宇宙中最温柔的神明。世界回报祂永不绝灭的繁荣，你们要与我一同记住祂的存在，不再忘记祂的名字。😫\n花繁叶茂、生灵挤挤，我们脚下的土地生生不息——爱莉希雅，这就是你想要守护的珍宝，这就是你为我留下的礼物。\n你说过，我们的足迹遍布地球，当我继续踏上这条路的时候，看见花木葱茏、云满湛空，还有那些洋溢着幸福的笑脸，就会再次见到你。😫\n是啊，这里的每一处，都有你的影子，我当然能够看到啊。可是我所渴求的，从来都不是这些……☹️\n我想要在广阔的星海里与我共享同一片风景、于漫长时间中朝夕相伴的爱莉希雅；我想要回到与你触之可及、真实共度的每一天。😢\n爱莉希雅……如果我当时说，请你不要离开我，你会愿意为我停留吗？😭\n“爱莉希雅最好了”';

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