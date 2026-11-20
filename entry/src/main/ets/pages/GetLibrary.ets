import { webview } from '@kit.ArkWeb';
import BackgroundImage from '../utils/BgImageManager';
import PasswordDialog from '../view/PasswordDialog';
import MessageDialog from '../view/MessageDialog';
import accountInfoProvider from '../utils/Encryption';
import { fillInformationJS } from '../utils/tools';
import UnifiedPreferences, { PASSWORD_KEY, REMIND_KEY, UID_KEY } from '../utils/UnifyPreference';
import { ExceptionPrompt, MarginType } from '@kit.ArkUI';
import {
  addItem, updateItem, filterItems, TodoItem, TodoType, IndexedTodoItem, DEFAULT_PRIORITY
} from '../utils/TodoStorage';

const BOOK_LIST_URL = 'https://opac.lib.ustc.edu.cn/reader/book_lst.php';
const CAS_PREFIX = 'https://id.ustc.edu.cn/cas/';
const OPAC_PREFIX = 'https://opac.lib.ustc.edu.cn/';
const LIBRARY_COURSE = '图书馆借阅';

/** 「当前借阅」页表格中的一本书 */
interface LibraryBookInfo {
  title: string;
  author: string;
  borrowDate: string;
  dueTime: number | null;
  location: string;
  barcode: string;
}

/**
 * 从汇文 OPAC v5.7「当前借阅」页提取借阅列表。
 * 表格 #tableSort 的每个数据行依次为：条码号、题名/责任者、借阅日期、
 * 应还日期、续借量、馆藏地、附件、续借按钮。
 * 不在该页面时返回 null，无在借图书时返回空数组。
 */
const borrowQueryJS = `
(() => {
    const table = document.getElementById('tableSort');
    if (!table) { return null; }
    const books = [];
    const rows = Array.from(table.rows).filter(tr => tr.querySelector('td') !== null);
    for (let i = 0; i < rows.length; i++) {
        const cells = rows[i].querySelectorAll('td');
        if (cells.length < 6) { continue; }
        const fullText = (cells[1].innerText || '').replace(/\\u00a0/g, ' ').trim();
        const link = cells[1].querySelector('a');
        const title = (link ? link.innerText : fullText).trim();
        if (title === '') { continue; }
        let author = '';
        const slash = fullText.lastIndexOf(' / ');
        if (slash >= 0) { author = fullText.slice(slash + 3).trim(); }
        const borrowDate = (cells[2].innerText || '').trim();
        const dueText = (cells[3].innerText || '').trim();
        const dm = dueText.match(/(\\d{4})-(\\d{1,2})-(\\d{1,2})/);
        const dueTime = dm
            ? new Date(Number(dm[1]), Number(dm[2]) - 1, Number(dm[3]), 23, 59).getTime()
            : null;
        books.push({
            title: title,
            author: author,
            borrowDate: borrowDate,
            dueTime: dueTime,
            location: (cells[5].innerText || '').trim(),
            barcode: (cells[0].innerText || '').trim()
        });
    }
    return JSON.stringify(books);
})()
`

@Builder
export function GLLibraryBuilder(name: string) {
  LibraryImportPage();
}

@Entry
@Component
struct LibraryImportPage {
  webviewController: webview.WebviewController = new webview.WebviewController();
  pathStack: NavPathStack = new NavPathStack();
  webAutoDarkMode: boolean = UnifiedPreferences.getBoolSync('webAutoDarkMode', true);
  haveTriedLogin: boolean = false;
  /** 登录成功后自动跳转「当前借阅」只做一次，避免重定向链循环触发 */
  jumpedToBookList: boolean = false;
  msgDialogController?: CustomDialogController;
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

  /** 解析 runJavaScript 返回的 JSON；兼容结果被再包一层引号的情况 */
  parseBooks(result: string): LibraryBookInfo[] | null {
    try {
      const parsed = JSON.parse(result) as LibraryBookInfo[] | string | null;
      if (Array.isArray(parsed)) {
        return parsed as LibraryBookInfo[];
      }
      if (typeof parsed === 'string') {
        const again = JSON.parse(parsed as string) as LibraryBookInfo[];
        return Array.isArray(again) ? again : null;
      }
      return null;
    } catch (e) {
      console.error('GetLibrary: parse failed:', JSON.stringify(e));
      return null;
    }
  }

  /** 显式复制一条 TodoItem（ArkTS 禁用 Object.assign 与无类型对象字面量） */
  copyItem(item: TodoItem): TodoItem {
    return {
      type: item.type,
      text: item.text,
      description: item.description,
      course: item.course,
      beginTime: item.beginTime,
      endTime: item.endTime,
      ddl: item.ddl,
      done: item.done,
      submitted: item.submitted,
      channels: item.channels,
      priority: item.priority,
      imagePaths: item.imagePaths?.slice()
    } as TodoItem;
  }

  /** 组装条目描述：责任者 ｜ 馆藏地 ｜ 借阅日期 ｜ 条码号 */
  buildDescription(book: LibraryBookInfo): string {
    const parts: string[] = [];
    if (book.location !== undefined && book.location !== '') {
      parts.push(`馆藏地 ${book.location}`);
    }
    if (book.borrowDate !== undefined && book.borrowDate !== '') {
      parts.push(`借阅日期 ${book.borrowDate}`);
    }
    if (book.author !== undefined && book.author !== '') {
      parts.push(`责任者 ${book.author}`);
    }
    if (book.barcode !== undefined && book.barcode !== '') {
      parts.push(`条码号 ${book.barcode}`);
    }
    return parts.join(' | ');
  }

  /** 执行页面脚本导入当前借阅；页面停留以便反复导入 */
  importBorrowed(): void {
    this.webviewController.runJavaScript(borrowQueryJS, (error, result) => {
      if (error) {
        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.import_failed'), duration: 2000 });
        return;
      }
      const books = this.parseBooks(result);
      if (books === null) {
        this.getUIContext().getPromptAction().showToast(
          { message: '请先登录并进入「当前借阅」页面', duration: 2500 });
        return;
      }
      if (books.length === 0) {
        this.getUIContext().getPromptAction().showToast({ message: '当前没有在借图书', duration: 2000 });
        return;
      }
      const existing = filterItems((item: TodoItem): boolean => item.course === LIBRARY_COURSE);
      const importedTexts: string[] = [];
      let added = 0;
      let updated = 0;
      books.forEach((book: LibraryBookInfo): void => {
        const title = (book.title ?? '').trim();
        if (title === '') {
          return;
        }
        const text = `归还《${title}》`;
        importedTexts.push(text);
        const description = this.buildDescription(book);
        let matchedIndex = -1;
        for (let i = 0; i < existing.length; i++) {
          if (existing[i].item.text.trim() === text) {
            matchedIndex = i;
            break;
          }
        }
        if (matchedIndex >= 0) {
          // 按书名更新：只改应还时间与描述，保留完成状态、重要度与附图
          const copy = this.copyItem(existing[matchedIndex].item);
          if (book.dueTime !== null && book.dueTime !== undefined) {
            copy.endTime = book.dueTime;
          }
          if (description !== '') {
            copy.description = description;
          }
          updateItem(existing[matchedIndex].index, copy);
          updated++;
        } else {
          const item: TodoItem = {
            type: TodoType.Todo,
            text: text,
            course: LIBRARY_COURSE,
            done: false,
            submitted: false,
            channels: [],
            priority: DEFAULT_PRIORITY
          };
          if (book.dueTime !== null && book.dueTime !== undefined) {
            item.endTime = book.dueTime;
          }
          if (description !== '') {
            item.description = description;
          }
          addItem(item);
          added++;
        }
      });
      this.getUIContext().getPromptAction().showToast({
        message: `已导入 ${books.length} 本（新增 ${added}，更新 ${updated}）`,
        duration: 2500
      });
      this.askMarkReturned(importedTexts);
    });
  }

  /** 询问是否把本次不在借阅列表中的旧条目（已归还）标记为完成 */
  askMarkReturned(importedTexts: string[]): void {
    const stale = filterItems((item: TodoItem): boolean =>
      item.course === LIBRARY_COURSE && !item.done && !importedTexts.includes(item.text.trim()));
    if (stale.length === 0) {
      return;
    }
    const names: string[] = [];
    stale.forEach((entry: IndexedTodoItem): void => {
      if (names.length < 3) {
        names.push(entry.item.text.replace(/^归还《/, '').replace(/》$/, ''));
      }
    });
    const summary = names.join('、') + (stale.length > names.length ? ' 等' : '');
    this.msgDialogController = new CustomDialogController({
      builder: MessageDialog({
        mainTitle: '借阅已归还',
        message: `有 ${stale.length} 本已归还的书仍在待办中（${summary}），要标记为已完成吗？`,
        onConfirm: () => {
          stale.forEach((entry: IndexedTodoItem): void => {
            const copy = this.copyItem(entry.item);
            copy.done = true;
            updateItem(entry.index, copy);
          });
        }
      }),
      autoCancel: true,
      gridCount: 4
    });
    this.msgDialogController.open();
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

      Text('导入借阅')
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
      .onClick(() => this.importBorrowed())
    }
    .padding({ left: 12, right: 12 })
    .alignItems(VerticalAlign.Center)
    .height(56)
    .width('100%')
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        Web({ src: BOOK_LIST_URL, controller: this.webviewController })
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
            this.loadError = event.error.getErrorInfo();
          })
          .onProgressChange((event) => {
            this.loadingProgress = event.newProgress;
          })
          .onPageBegin(() => {
            this.loadError = '';
          })
          .onPageEnd(() => {
            const url = this.webviewController.getUrl();
            // 登录后自动进入「当前借阅」，仅跳转一次
            if (!this.haveTriedLogin && url.startsWith(CAS_PREFIX)) {
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
              return;
            }
            if (!this.jumpedToBookList && url.startsWith(OPAC_PREFIX) &&
              !url.includes('book_lst.php') && !url.includes('login.php') &&
              !url.includes('oauth_callback.php')) {
              this.jumpedToBookList = true;
              this.webviewController.loadUrl(BOOK_LIST_URL);
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
            tip: '登录后进入「我的图书馆 → 当前借阅」，点右上角导入借阅',
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