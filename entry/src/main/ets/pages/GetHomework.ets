import { webview } from '@kit.ArkWeb';
import BackgroundImage from '../utils/BgImageManager';
import PasswordDialog from '../view/PasswordDialog';
import accountInfoProvider from '../utils/Encryption';
import { fillInformationJS } from '../utils/tools';
import UnifiedPreferences, { PASSWORD_KEY, REMIND_KEY, UID_KEY } from '../utils/UnifyPreference';
import { ExceptionPrompt, MarginType } from '@kit.ArkUI';
import { addItem, TodoItem, TodoType, SubmitChannel, DEFAULT_PRIORITY } from '../utils/TodoStorage';

/**
 * BB 作业上传页面提取出的作业信息，导入时由本页直接组装为待办写入 TodoStorage。
 */
export interface BBHomeworkInfo {
  /** 作业标题（已去掉“上载作业：”前缀） */
  title: string,
  /** 课程名（取自面包屑），未取到时为空串 */
  course: string,
  /** 作业说明文本，未取到时为空串 */
  description: string,
  /** 截止时间（毫秒时间戳），页面未提供时为 null */
  ddl: number | null
}

/**
 * 在 BB 作业上传页提取作业信息：该页以 id 为 uploadAssignmentFormId 的上传表单
 * 为标志，标题、课程与说明均来自服务端渲染的固定结构（参考 homework.html）。
 * 非上传页面返回 null。
 */
const homeworkQueryJS = `
(() => {
    const form = document.getElementById('uploadAssignmentFormId');
    if (!form) { return null; }
    let title = '';
    const titleEl = document.getElementById('pageTitleText');
    if (titleEl) {
        title = titleEl.innerText.replace(/^\\s*上载作业\\s*[：:]\\s*/, '').trim();
    }
    let course = '';
    const courseEl = document.querySelector('#breadcrumbs li.coursePath a');
    if (courseEl) { course = courseEl.innerText.trim(); }
    let description = '';
    const descEl = document.querySelector('#instructions .vtbegenerated');
    if (descEl) { description = descEl.innerText.trim(); }
    let ddl = null;
    const sections = document.querySelectorAll('.metaSection');
    for (let i = 0; i < sections.length; i++) {
        const label = sections[i].querySelector('.metaLabel');
        const field = sections[i].querySelector('.metaField');
        if (label === null || field === null || label.innerText.indexOf('截止') < 0) { continue; }
        const text = field.innerText;
        const dm = text.match(/(\\d{4})[年\\-\\/.](\\d{1,2})[月\\-\\/.](\\d{1,2})/);
        if (dm) {
            let hour = 23;
            let minute = 59;
            const tm = text.match(/(\\d{1,2}):(\\d{2})/);
            if (tm) {
                hour = Number(tm[1]);
                minute = Number(tm[2]);
                // 十二小时制标记：中文“下午5:00”在时间前，英文“5:00 PM”在时间后
                const isPm = /[下晚][\\s\\u00a0]*午|[Pp]\\s*\\.?\\s*[Mm]/.test(text);
                const isAm = /[上早凌][\\s\\u00a0]*[午晨]|[Aa]\\s*\\.?\\s*[Mm]/.test(text);
                if (isPm && hour < 12) { hour += 12; }
                else if (isAm && hour === 12) { hour = 0; }
            }
            ddl = new Date(Number(dm[1]), Number(dm[2]) - 1, Number(dm[3]), hour, minute).getTime();
        }
        break;
    }
    return JSON.stringify({ title: title, course: course, description: description, ddl: ddl });
})()
`

@Builder
export function GHWBuilder(name: string) {
  HomeworkImportPage();
}

@Entry
@Component
struct HomeworkImportPage {
  webviewController: webview.WebviewController = new webview.WebviewController();
  pathStack: NavPathStack = new NavPathStack();
  webAutoDarkMode: boolean = UnifiedPreferences.getBoolSync('webAutoDarkMode', true);
  haveTriedLogin: boolean = false;
  dialogController: CustomDialogController = new CustomDialogController({
    builder: PasswordDialog({
      isFromSetting: false,
      onConfirm: () => {
        this.haveTriedLogin = true;
        this.webviewController.runJavaScript(fillInformationJS);
      }
    }),
    autoCancel: false
  })
  @State loadingProgress: number = 0;
  @State loadError: string = '';
  @State showGetHint: boolean = true;

  /** 执行页面脚本提取作业信息，直接写入待办存储；页面停留以便连续导入多个作业 */
  importHomework(): void {
    this.webviewController.runJavaScript(homeworkQueryJS, (error, result) => {
      if (error) {
        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.import_failed'), duration: 2000 });
        return;
      }
      let info: BBHomeworkInfo | null = null;
      try {
        info = JSON.parse(result) as BBHomeworkInfo;
      } catch (e) {
        console.error('GetHomework: parse failed:', JSON.stringify(e));
        info = null;
      }
      if (info === null || info.title === undefined) {
        // runJavaScript 对字符串结果可能再包一层 JSON 引号，尝试二次解析
        try {
          info = JSON.parse((JSON.parse(result) as object).toString()) as BBHomeworkInfo;
        } catch (e) {
          info = null;
        }
      }
      if (info === null || info.title === undefined || info.title.trim() === '') {
        this.getUIContext().getPromptAction().showToast(
          { message: '请先进入作业的「上载作业」页面再导入', duration: 2500 });
        return;
      }
      const item: TodoItem = {
        type: TodoType.Assignment,
        text: info.title,
        done: false,
        submitted: false,
        channels: [SubmitChannel.Blackboard],
        priority: DEFAULT_PRIORITY
      };
      if (info.course !== undefined && info.course !== '') {
        item.course = info.course;
      }
      if (info.description !== undefined && info.description !== '') {
        item.description = info.description;
      }
      if (info.ddl !== null && info.ddl !== undefined) {
        item.ddl = info.ddl;
      }
      addItem(item);
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.import_success') });
    })
  }

  @Builder customTitle() {
    Row({ space: 6 }) {
      Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
        Image($r('app.media.close'))
          .height(22)
          .draggable(false)
      }
      .height(40)
      .width(40)
      .onClick(() => {
        this.webviewController.terminateRenderProcess();
        this.pathStack.pop();
      })

      Text('导入作业')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
        Image($r('app.media.back'))
          .height(22)
          .draggable(false)
      }
      .height(40)
      .width(40)
      .onClick(() => {
        if (this.webviewController.accessBackward()) {
          this.webviewController.backward();
        } else {
          this.getUIContext().getPromptAction().showToast(
            { message: $r('app.string.already_first_page'), duration: 500 });
        }
      })

      Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
        Image($r('app.media.refresh'))
          .height(22)
          .draggable(false)
      }
      .height(40)
      .width(40)
      .onClick(() => this.webviewController.refresh())

      Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
        Image($r('app.media.get'))
          .height(22)
          .draggable(false)
      }
      .height(40)
      .width(40)
      .onClick(() => this.importHomework())
    }
    .padding({ left: 12, right: 12 })
    .alignItems(VerticalAlign.Center)
    .height(56)
    .width('100%')
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        Web({ src: 'https://www.bb.ustc.edu.cn', controller: this.webviewController })
          .javaScriptProxy({
            object: accountInfoProvider,
            name: "infoProvider",
            methodList: ["getUID", "getPassword"],
            controller: this.webviewController,
            asyncMethodList: []
          })
          .domStorageAccess(true)
          .javaScriptAccess(true)
          .width('100%')
          .height('100%')
          .darkMode(this.webAutoDarkMode ? WebDarkMode.Auto : WebDarkMode.Off)
          .forceDarkAccess(this.webAutoDarkMode)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          .backgroundColor(BackgroundImage.blurLevel === undefined ? undefined : '#0000')
          .onErrorReceive((event) => {
            // Only handle loading errors of the main framework to avoid duplicate processing of errors in sub-resources
            this.loadError = event.error.getErrorInfo();
          })
          .onProgressChange((event) => {
            this.loadingProgress = event.newProgress;
          })
          .onPageBegin(() => {
            this.loadError = '';
          })
          .onPageEnd(() => {
            // 跳转到统一身份认证登录页时自动填充账号密码
            if (!this.haveTriedLogin && this.webviewController.getUrl().startsWith('https://id.ustc.edu.cn/cas/login')) {
              if (!(UnifiedPreferences.hasSync(UID_KEY) && UnifiedPreferences.hasSync(PASSWORD_KEY))) {
                if (UnifiedPreferences.getBoolSync(REMIND_KEY, true)) {
                  this.dialogController.open();
                }
              } else {
                this.haveTriedLogin = true;
                this.webviewController.runJavaScript(fillInformationJS, (error, result) => {
                  console.info(`自动填写uid：${UnifiedPreferences.getSync(UID_KEY)}`);
                });
              }
            }
          })

        if (this.loadError !== '') {
          Column() {
            Column() {
              Image($r('app.media.thinking'))
                .layoutWeight(1)
                .objectFit(ImageFit.Contain)
                .constraintSize({ maxWidth: '60%', maxHeight: 300 })
              Text($r('app.string.network_error'))
                .fontWeight(FontWeight.Bold)
                .fontSize(30)
                .fontColor($r('app.color.red'))
              Text($r('app.string.network_error_explain', this.loadError))
                .textAlign(TextAlign.Center)
                .margin({ top: 6, bottom: 10 })
                .fontColor(this.webAutoDarkMode ? $r('app.color.normal_text') : '#000000')
              Row({ space: 6 }) {
                Button($r('app.string.back_to_last_page'))
                  .onClick(() => {
                    if (this.webviewController.accessBackward()) {
                      this.webviewController.backward();
                    } else {
                      this.webviewController.terminateRenderProcess();
                      this.pathStack.pop();
                    }
                  })
                Button($r('app.string.refresh'))
                  .onClick(() => {
                    this.webviewController.refresh();
                  })
                Button($r('app.string.close_this_hint'))
                  .onClick(() => {
                    this.loadError = '';
                    this.getUIContext().getPromptAction().showToast({ message: $r('app.string.after_close') });
                  })
              }
            }
            .padding({ left: 12, right: 12 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }

        ExceptionPrompt({
          options: {
            tip: '登录后进入「作业区→上载作业」，在右上角可导入为作业',
            marginType: MarginType.DEFAULT_MARGIN,
            marginTop: 7,
            isShown: this.showGetHint,
            icon: $r('app.media.lightbulb')
          },
          onTipClick: () => this.showGetHint = false
        })

        Line()
          .visibility(this.loadingProgress == 100 ? Visibility.None : Visibility.Visible)
          .width(`${this.loadingProgress}%`)
          .height(5)
          .startPoint([0, 0])
          .backgroundColor($r('app.color.pink'));
        Row({ space: 5 }) {
          LoadingProgress()
            .width(45)
            .height(45)
            .color($r('app.color.pink'));
          Text($r('app.string.loading'))
            .fontColor($r('app.color.pink'));
        }
        .padding({ left: 5, top: 5 })
        .visibility(this.loadingProgress === 100 ? Visibility.None : Visibility.Visible);
      }
      .height('100%')
      .width('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .title(this.customTitle(), {
      backgroundColor: (BackgroundImage.blurLevel === undefined ? BackgroundImage.titleBackgroundColor : '#0000')
    })
    .hideBackButton(true)
    .backgroundColor('#0000')
    .backgroundBlurStyle(BackgroundImage.blurLevel)
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
    .onBackPressed(() => {
      this.webviewController.terminateRenderProcess();
      return false;
    })
  }
}
