import BackgroundImage from '../../utils/BgImageManager';
import { answerStore } from '../../utils/MockPractice/AnswerSessionManager';
import { sessionNavParam, sessionSummary, singleQuestion } from '../../utils/MockPractice/constants';


@Builder
export function MPMBuilder(name: string, param?: Object) {
  MockPracticeMain({ navParam: param as sessionNavParam })
}

const answerColor: (Resource | string)[] = [$r('app.color.green'), $r('app.color.red'), '#f59e0b', $r('app.color.grid_background')];
const COLOR_GREEN = 0;
const COLOR_RED = 1;
const COLOR_YELLOW = 2;
const COLOR_NONE = 3;

/** 提交后选项/反馈的着色与动画时长 */
const FLASH_MS: number = 400;

@Entry
@Component
struct MockPracticeMain {
  navParam: sessionNavParam = { bankId: '', bankName: '', sessionId: '' };
  @State q: singleQuestion | null = null;
  @State current: number = 0;
  @State total: number = 0;
  /** 本次练习已完成，展示总结视图 */
  @State finished: boolean = false;
  /** 导航参数失效（记录或题库不存在） */
  @State broken: boolean = false;
  @State summary: sessionSummary | null = null;
  @State singleChoice: number = -1;
  @State multiChoice: boolean[] = [];
  @State textAnswer: string = '';
  @State optionColor: number[] = [];
  @State feedback: string = '';
  @State feedbackCorrect: boolean = false;
  // 作答后的扫过动画（覆盖在题目与选项上的色块）
  @State rectHeight: number[] = [];
  @State qHeight: number = 60;
  @State rectOffset: number = 0;
  @State initialized: boolean = false;
  private optionWidth: number = 0;
  pathStack: NavPathStack = new NavPathStack();

  /** 拉取当前题并重置与单题相关的作答状态；进度（current/total）一并向 store 对齐 */
  loadQuestion(): void {
    const progress = answerStore.getProgress(this.navParam.bankId, this.navParam.sessionId);
    this.total = progress.total;
    this.current = progress.position;
    const question = answerStore.getCurrentQuestion(this.navParam.bankId, this.navParam.sessionId);
    if (question === null) {
      this.showFinish();
      return;
    }
    const optionCount = question.type === 'blank' ? 0 : question.optionCount;
    this.q = question;
    this.singleChoice = -1;
    this.multiChoice = [];
    for (let i = 0; i < optionCount; i++) {
      this.multiChoice.push(false);
    }
    this.optionColor = [];
    for (let i = 0; i < optionCount; i++) {
      this.optionColor.push(COLOR_NONE);
    }
    this.textAnswer = '';
    this.feedback = '';
    this.rectHeight = [];
  }

  showFinish(): void {
    this.q = null;
    const progress = answerStore.getProgress(this.navParam.bankId, this.navParam.sessionId);
    this.summary = progress;
    this.finished = progress.total > 0;
    this.broken = progress.total === 0;
  }

  clearFeedback(): void {
    this.feedback = '';
    if (this.q !== null) {
      const optionCount = this.q.type === 'blank' ? 0 : this.q.optionCount;
      this.optionColor = [];
      for (let i = 0; i < optionCount; i++) {
        this.optionColor.push(COLOR_NONE);
      }
    }
  }

  /** 按判定结果给选项着色：绿=选对，红=选错，黄=漏选的正确项 */
  applyFeedback(isCorrect: boolean): void {
    const q = this.q;
    if (q === null) {
      return;
    }
    if (q.type === 'single') {
      for (let i = 0; i < q.optionCount; i++) {
        if (isCorrect && i === this.singleChoice) {
          this.optionColor[i] = COLOR_GREEN;
        } else if (!isCorrect && i === this.singleChoice) {
          this.optionColor[i] = COLOR_RED;
        } else if (!isCorrect && String.fromCharCode(65 + i) === q.answer.trim().toUpperCase()) {
          this.optionColor[i] = COLOR_YELLOW;
        } else {
          this.optionColor[i] = COLOR_NONE;
        }
      }
    } else if (q.type === 'multiple') {
      for (let i = 0; i < q.optionCount; i++) {
        const alphabet = String.fromCharCode(65 + i);
        const picked = this.multiChoice[i] === true;
        const inAnswer = q.answer.trim().toUpperCase().includes(alphabet);
        if (picked && inAnswer) {
          this.optionColor[i] = COLOR_GREEN;
        } else if (picked && !inAnswer) {
          this.optionColor[i] = COLOR_RED;
        } else if (!picked && inAnswer) {
          this.optionColor[i] = COLOR_YELLOW;
        } else {
          this.optionColor[i] = COLOR_NONE;
        }
      }
    }
  }

  buildUserAnswer(): string {
    const q = this.q;
    if (q === null) {
      return '';
    }
    if (q.type === 'single') {
      if (this.singleChoice < 0) {
        this.getUIContext().getPromptAction().showToast({ message: '请先选择一个选项', duration: 1500 });
        return '';
      }
      return String.fromCharCode(65 + this.singleChoice);
    }
    if (q.type === 'multiple') {
      const picked: string[] = [];
      for (let i = 0; i < q.optionCount; i++) {
        if (this.multiChoice[i] === true) {
          picked.push(String.fromCharCode(65 + i));
        }
      }
      if (picked.length === 0) {
        this.getUIContext().getPromptAction().showToast({ message: '请至少选择一个选项', duration: 1500 });
        return '';
      }
      return picked.join('');
    }
    const text = this.textAnswer.trim();
    if (text === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入答案', duration: 1500 });
      return '';
    }
    return text;
  }

  submit(): void {
    const userAnswer = this.buildUserAnswer();
    if (userAnswer === '') {
      return;
    }
    const isCorrect = answerStore.submitAnswer(this.navParam.bankId, this.navParam.sessionId, userAnswer);
    this.applyFeedback(isCorrect);
    this.feedback = isCorrect ? '回答正确' : `回答错误，正确答案：${this.q?.answer || ''}`;
    this.feedbackCorrect = isCorrect;

    // 色块扫过动画
    this.rectOffset = -this.optionWidth;
    this.initialized = true;
    this.getUIContext().animateTo({ curve: Curve.EaseOut, duration: 300 }, () => {
      this.rectOffset = 0;
    });
    setTimeout(() => {
      if (isCorrect) {
        // 提交时进度已自动前进；没有下一题即完成本次练习
        this.loadQuestion();
      }
      setTimeout(() => {
        this.getUIContext().animateTo({ curve: Curve.EaseIn, duration: 300 }, () => {
          this.rectOffset = this.optionWidth;
        });
      }, 100);
    }, FLASH_MS);
  }

  navigateTo(delta: number): void {
    answerStore.jumpTo(this.navParam.bankId, this.navParam.sessionId, this.current + delta);
    this.loadQuestion();
  }

  openRecord(): void {
    this.pathStack.pushPath({
      name: 'MockPracticeRecord',
      param: {
        bankId: this.navParam.bankId,
        bankName: this.navParam.bankName,
        sessionId: this.navParam.sessionId
      } as sessionNavParam
    });
  }

  build() {
    NavDestination() {
      Column() {
        if (this.broken) {
          Column() {
            Text('未找到该做题记录')
              .fontSize(16)
            Button('返回')
              .margin({ top: 16 })
              .onClick(() => {
                this.pathStack.pop();
              })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.finished) {
          Column() {
            Text('🎉')
              .fontSize(40)
            Text('本次练习已完成')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 12 })
            if (this.summary !== null) {
              Text(`答对 ${this.summary.correct} / 共 ${this.summary.total} 题` +
                (this.summary.answered > 0 ? ` · 正确率 ${Math.round(this.summary.correct * 100 / this.summary.answered)}%` : ''))
                .fontSize(15)
                .margin({ top: 8 })
            }
            Row() {
              Button('查看做题记录')
                .buttonStyle(ButtonStyleMode.EMPHASIZED)
                .onClick(() => {
                  this.openRecord();
                })
              Button('返回')
                .buttonStyle(ButtonStyleMode.TEXTUAL)
                .onClick(() => {
                  this.pathStack.pop();
                })
            }
            .margin({ top: 20 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          Scroll() {
            Column() {
              Stack() {
                Text() {
                  Span(`${this.current + 1}/${this.total}  `)
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                  Span(this.q?.context || '')
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

          if (this.q?.type === 'blank') {
            TextInput({ text: this.textAnswer, placeholder: '请输入答案' })
              .margin({ left: 12, right: 12, top: 8 })
              .onChange((value: string) => {
                this.textAnswer = value;
                this.clearFeedback();
              })
          } else {
            Column() {
              ForEach(this.q?.options || [], (optionContext: string, index: number) => {
                Stack() {
                  Row() {
                    Text(String.fromCharCode(65 + index))
                      .fontWeight(FontWeight.Bold)
                      .margin({ left: 10, right: 10 })
                    Text(optionContext)
                      .layoutWeight(1)
                  }
                  .padding(4)
                  .borderWidth((this.q?.type === 'multiple' && this.multiChoice[index])
                    || (this.q?.type === 'single' && this.singleChoice === index)
                    ? 3 : undefined)
                  .constraintSize({ minHeight: 40 })
                  .width('100%')
                  .justifyContent(FlexAlign.Start)
                  .onClick(() => {
                    if (this.q?.type === 'multiple') {
                      this.multiChoice[index] = !this.multiChoice[index];
                    } else {
                      this.singleChoice = index;
                    }
                    this.clearFeedback();
                  })
                  .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions) => {
                    this.rectHeight[index] = newValue.height as number;
                  })

                  Rect()
                    .height(this.rectHeight[index] || 40)
                    .width('100%')
                    .fill(answerColor[this.optionColor[index] === undefined ? COLOR_NONE : this.optionColor[index]])
                    .visibility(this.initialized ? Visibility.Visible : Visibility.None)
                    .offset({ x: this.rectOffset })
                }
                .clip(true)
                .width('100%')
                .margin({ top: 8, bottom: 6 })
                .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
                .borderRadius(20)
              }, (optionContext: string, index: number) => `${this.current}-${index}-${optionContext}`)
            }
            .padding({ left: 12, right: 12 })
            .onSizeChange((_oldValue: SizeOptions, newValue: SizeOptions) => {
              this.optionWidth = (newValue.width as number);
            })
            .width('100%')
          }

          if (this.feedback !== '') {
            Text(this.feedback)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.feedbackCorrect ? $r('app.color.green') : $r('app.color.red'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .margin({ top: 8 })
          }

          Row() {
            Button('上一题')
              .buttonStyle(ButtonStyleMode.TEXTUAL)
              .enabled(this.current > 0)
              .onClick(() => {
                this.navigateTo(-1);
              })

            Button('提交')
              .buttonStyle(ButtonStyleMode.EMPHASIZED)
              .onClick(() => {
                this.submit();
              })
            Button('下一题')
              .buttonStyle(ButtonStyleMode.TEXTUAL)
              .enabled(this.current + 1 < this.total)
              .onClick(() => {
                this.navigateTo(1);
              })
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.shaded_background' + String(BackgroundImage.themeColor)) : undefined)
          .backgroundBlurStyle(BackgroundImage.blurLevel)
          .width('100%')
          .padding({ top: 6, bottom: 6 })
        }
      }
      .width('100%')
      .height('100%')
    }
    .title(this.navParam.bankName, {
      backgroundBlurStyle: BackgroundImage.blurLevel,
      backgroundColor: BackgroundImage.blurLevel === undefined ? $r('app.color.shaded_background' + String(BackgroundImage.themeColor)) : undefined
    })
    .backButtonIcon($r('app.media.close'))
    .backgroundColor(BackgroundImage.showImage ? '#00d00721' : $r('app.color.normal_background'))
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
      this.loadQuestion();
    })
    .onShown(() => {
      // 从记录页返回时恢复到最新进度
      this.loadQuestion();
    })
  }
}
