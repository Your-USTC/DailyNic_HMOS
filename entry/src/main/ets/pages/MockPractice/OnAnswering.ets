import BackgroundImage, { presetColor } from '../../utils/BgImageManager';
import { answerStore } from '../../utils/MockPractice/AnswerSessionManager';
import { fullID, singleQuestion, testAttribute } from '../../utils/MockPractice/constants';
import { getAllTest } from '../../utils/MockPractice/TestManager';
import { curves } from '@kit.ArkUI';


@Builder
export function MPMBuilder(name: string, param?: fullID) {
  MockPracticeMain({ sessionId: param });
}

const answerColor: (Resource | string)[] = [$r('app.color.green'), $r('app.color.red'), '#f59e0b', $r('app.color.grid_background')]

@Entry
@Component
struct MockPracticeMain {
  @State practiceList: testAttribute[] = getAllTest();
  // questionDescription: string = 'simple';
  sessionId: fullID = { name: 'test', test: '', answer: '' };
  @State singleChoice: number = -1;
  @State multiChoice: boolean[] = [];
  @State textAnswer: string = '';
  @State q: singleQuestion | null = null;
  @State result: string = '';
  @State current: number = 0;
  @State total: number = 0;
  @State rectHeight: number[] = [];
  @State qHeight: number = 60;
  @State rectOffset: number = 0;
  @State initialized: boolean = false;
  private optionWidth: number = 0;
  @State optionColor: number[] = [];

  menuItems: Array<NavigationMenuItem> = [
    {
      value: 'list',
      icon: $r('app.media.save'),
      action: () => {
        answerStore.save(this.sessionId.test);
      }
    }
  ];
  pathStack: NavPathStack = new NavPathStack();
  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Column() {
            Stack() {
              Text() {
                Span(`${this.current + 1}/${this.total}`)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                Span(this.q?.context || '读取题目时出现错误')
                Span(this.result)
              }
              .width('100%')
              .constraintSize({ minHeight: 60 })
              .padding(12)

              Rect()
                .height(this.qHeight)
                .width('100%')
                .fill($r('app.color.green'))
                .visibility(this.initialized ? Visibility.Visible : Visibility.None)
                .offset({ x: this.rectOffset })
            }
            .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
            .borderRadius(20)
            .clip(true)
            .onSizeChange((_oldValue: SizeOptions, newValue: SizeOptions) => {
              this.qHeight = newValue.height as number;
            })

            Blank().layoutWeight(1)
          }
          .width('100%')
        }
        .width('calc(100% - 24vp)')
        .borderRadius(20)
        .margin({ top: 12, left: 12, right: 12 })
        .layoutWeight(1)

        if (this.q?.type === "blank") {
          TextInput({ placeholder: this.textAnswer })
        } else {
          Column() {
            ForEach(this.q?.options || ['读取选项时出现错误'], (optionContext: string, index: number) => {
              Stack() {
                Row() {
                  Text(String.fromCharCode(65 + index))
                    .fontWeight(FontWeight.Bold)
                    .margin({ left: 10, right: 10 })
                  Text(optionContext)
                    .layoutWeight(1)
                }
                .padding(4)
                .borderWidth((this.q?.type === "multiple" && this.multiChoice[index])
                  || (this.q?.type === "single" && this.singleChoice === index)
                  ? 3 : undefined)
                .constraintSize({ minHeight: 40 })
                .width('100%')
                .justifyContent(FlexAlign.Start)
                .onClick(() => {
                  if (this.q?.type === "multiple")
                    this.multiChoice[index] = !this.multiChoice[index];
                  else
                    this.singleChoice = index;
                })
                .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions) => {
                  this.rectHeight[index] = newValue.height as number;
                })

                Rect()
                  .height(this.rectHeight[index])
                  .width('100%')
                  .fill(answerColor[this.optionColor[index]])
                  .visibility(this.initialized ? Visibility.Visible : Visibility.None)
                  .offset({ x: this.rectOffset })
              }
              .clip(true)
              .width('100%')
              .margin({ top: 8, bottom: 6 })
              .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
              .borderRadius(20)
            })
          }
          .padding({ left: 12, right: 12 })
          .onSizeChange((_oldValue: SizeOptions, newValue: SizeOptions) => {
            this.optionWidth = (newValue.width as number);
          })
          .width('100%')
        }

        Row() {
          Button('上一题')
            .buttonStyle(ButtonStyleMode.TEXTUAL)
            .onClick(() => {
              if (this.current > 0)
                this.current--;
              answerStore.jumpTo(this.sessionId.test, this.sessionId.answer, this.current);
              this.q = answerStore.getCurrentQuestion(this.sessionId.test, this.sessionId.answer);
            })

          Button('提交')
            .buttonStyle(ButtonStyleMode.TEXTUAL)
            .onClick(() => {
              let userAnswer: string;
              if (this.q?.type === "single") {
                userAnswer = String.fromCharCode(65 + this.singleChoice);
                if (userAnswer === this.q?.answer) { // 回答正确
                  for (let i = 0; i < this.q?.optionCount; i++)
                    if (i === this.singleChoice) {
                      this.optionColor[i] = 0;
                    } else {
                      this.optionColor[i] = 3;
                    }
                } else { // 回答错误
                  for (let i = 0; i < this.q?.optionCount; i++)
                    if (i === this.singleChoice) {
                      this.optionColor[i] = 1;
                    } else if (String.fromCharCode(65 + i) === this.q?.answer) {
                      this.optionColor[i] = 2;
                    } else {
                      this.optionColor[i] = 3;
                    }
                }
                this.singleChoice = -1;
              } else if (this.q?.type === "multiple") {
                const cache: string[] = [];
                for (let index = 0; index < this.q?.optionCount; index++) {
                  const ansAlphabet = String.fromCharCode(65 + index);
                  if (this.multiChoice[index]) {
                    cache.push(ansAlphabet);
                    if (this.q?.answer.includes(ansAlphabet)) {
                      this.optionColor[index] = 0; // GREEN
                    } else {
                      this.optionColor[index] = 1; // RED
                    }
                  } else {
                    if (this.q?.answer.includes(ansAlphabet)) {
                      this.optionColor[index] = 2; // YELLOW
                    } else {
                      this.optionColor[index] = 3; // WHITE
                    }
                  }
                }
                userAnswer = cache.join('');
                console.log('!!!' + JSON.stringify(this.multiChoice));
                this.multiChoice = [];
              } else {
                userAnswer = this.textAnswer;
                this.textAnswer = '';
              }

              this.rectOffset = -this.optionWidth;
              this.initialized = true;
              this.getUIContext().animateTo({ curve: Curve.EaseOut, duration: 300 }, () => {
                this.rectOffset = 0;
              });
              setTimeout(() => {
                const judge = answerStore.submitAnswer(this.sessionId.test, this.sessionId.answer, userAnswer);
                this.result = this.q?.answer || 'no answer';
                if (judge) {
                  this.current++;
                  this.q = answerStore.getCurrentQuestion(this.sessionId.test, this.sessionId.answer);
                } else {
                  answerStore.jumpTo(this.sessionId.test, this.sessionId.answer, this.current);
                }
                setTimeout(() => {
                  this.getUIContext().animateTo({ curve: Curve.EaseIn, duration: 300 }, () => {
                    this.rectOffset = this.optionWidth;
                  })}, 100);
              }, 400);
            })
          Button('下一题')
            .buttonStyle(ButtonStyleMode.TEXTUAL)
            .onClick(() => {
              if (this.current + 1 < this.total)
              this.current++;
              answerStore.jumpTo(this.sessionId.test, this.sessionId.answer, this.current);
              this.q = answerStore.getCurrentQuestion(this.sessionId.test, this.sessionId.answer);
            })
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
        .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.shaded_background' + String(BackgroundImage.themeColor)) : undefined)
        .backgroundBlurStyle(BackgroundImage.blurLevel)
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .height('100%')
    }
    .title(this.sessionId.name, {
      backgroundBlurStyle: BackgroundImage.blurLevel,
      backgroundColor: BackgroundImage.blurLevel === undefined ? $r('app.color.shaded_background' + String(BackgroundImage.themeColor)) : undefined
    })
    .menus(this.menuItems)
    .backButtonIcon($r('app.media.close'))
    .backgroundColor(BackgroundImage.showImage ? '#00d00721' : $r('app.color.normal_background'))
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
      this.q = answerStore.getCurrentQuestion(this.sessionId.test, this.sessionId.answer);
      // for (let i = 0; i < (this.q?.optionCount || 0); i++)
      //   this.optionColor[i] = 3;
      this.total = answerStore.getProgress(this.sessionId.test, this.sessionId.answer).total;
    })
  }
}