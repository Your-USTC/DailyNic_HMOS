import BackgroundImage, { presetColor } from '../utils/BgImageManager';
import MessageDialog from '../view/MessageDialog';
import {
  TodoItem, TodoType, SubmitChannel, IndexedTodoItem, getItems,
  addItem, updateItem, removeItem, filterItems, getEffectiveTime,
  importImage, DEFAULT_PRIORITY, MAX_PRIORITY
} from '../utils/TodoStorage';
import ScheduleManager from '../utils/Classes/ScheduleManager';
import * as ScheduleStorage from '../utils/ScheduleStorage';
import { classAttribute } from '../constants/ScheduleSources';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileUri } from '@kit.CoreFileKit';
import {
  CounterComponent, CounterType,
  SegmentButton, SegmentButtonOptions, SegmentButtonItemTuple
} from '@kit.ArkUI';
import { ImagePreview } from 'module_imagepreview';

/** 提交渠道显示名，下标与 SubmitChannel 枚举值对应 */
const CHANNEL_NAMES: string[] = ['BB系统', 'QQ', '邮箱', '线上', '线下'];

/**
 * 编辑弹窗草稿中的一张附图。
 * uri 统一用于 Image 展示与 ImagePreview 预览；
 * path 为已保存到私有目录的绝对路径，缺省表示本次新选取、保存时才导入。
 */
interface DraftImage {
  uri: string;
  path?: string;
}

@Builder
export function TodoBuilder(name: string, param?: object) {
  TodoPage();
}

@Entry
@Component
struct TodoPage {

  pathStack: NavPathStack = new NavPathStack();
  msgDialogController?: CustomDialogController;

  /** 当前列表（已过滤、已按有效时间升序），index 为原始数组下标 */
  @State todoList: IndexedTodoItem[] = [];
  /** 过滤类型：-1 全部，其余为 TodoType */
  @State filterType: number = -1;
  @State showSheet: boolean = false;
  /** 正在编辑的条目原始下标，-1 表示新建 */
  @State editingIndex: number = -1;

  /** 课程过滤：'' 表示全部，其余为课程名 */
  @State filterCourse: string = '';
  /** 列表条目中出现过的课程名（用于过滤栏） */
  @State filterCourseNames: string[] = [];
  /** 搜索关键词，空串表示不搜索（匹配内容与课程名，忽略大小写） */
  @State searchText: string = '';
  /** 状态过滤：-1 全部，0 未完成，1 已完成（作业以 done || submitted 计） */
  @State filterStatus: number = -1;
  /** 是否展示筛选栏（类型/课程/状态下拉），搜索框常驻 */
  @State showFilter: boolean = false;
  /** 编辑弹窗草稿：课程分类 */
  @State draftCourse: string = '';
  /** 默认学期课表中的课程名列表（去重），供快速填写 */
  @State courseNames: string[] = [];
  /** 搜索防抖定时器 */
  searchDebounceTimer: number | null = null;

  // 编辑弹窗草稿
  @State draftType: TodoType = TodoType.Todo;
  /** 类型分段按钮选中项下标（0 待办事项 / 1 作业），与 draftType 同步 */
  @State draftTypeIndexes: number[] = [0];
  /** 类型分段按钮配置，颜色随主题在 refresh 中刷新 */
  @State draftTypeOptions: SegmentButtonOptions = SegmentButtonOptions.capsule({
    buttons: [{ text: '待办事项' }, { text: '作业' }] as SegmentButtonItemTuple,
    multiply: false,
    fontColor: presetColor[BackgroundImage.themeColor].accentColor,
    selectedFontColor: '#ffffff',
    backgroundColor: '#33888888',
    selectedBackgroundColor: presetColor[BackgroundImage.themeColor].accentColor
  });
  @State draftText: string = '';
  @State draftBeginDisabled: boolean = false;
  @State draftEndDisabled: boolean = true;
  @State draftBeginDate: string = '2026-01-01';
  @State draftEndDate: string = '2026-01-01';
  @State beginHour: number = 8;
  @State beginMinute: number = 0;
  @State endHour: number = 22;
  @State endMinute: number = 0;
  @State draftChannels: boolean[] = [false, false, false, false, false];
  /** 编辑弹窗草稿：重要度 0-10 */
  @State draftPriority: number = DEFAULT_PRIORITY;
  /** 编辑弹窗草稿：附图列表（统一以 uri 展示/预览，path 标记已保存项） */
  @State draftImages: DraftImage[] = [];

  refresh(): void {
    // SegmentButton 的颜色保存在 options 中，主题变化时需手动同步
    const accent = presetColor[BackgroundImage.themeColor].accentColor;
    this.draftTypeOptions.fontColor = accent;
    this.draftTypeOptions.selectedBackgroundColor = accent;
    const courseSet: string[] = [];
    getItems().forEach((item: TodoItem): void => {
      if (item.course !== undefined && item.course !== '' && !courseSet.includes(item.course)) {
        courseSet.push(item.course);
      }
    });
    this.filterCourseNames = courseSet;
    if (this.filterCourse !== '' && !courseSet.includes(this.filterCourse)) {
      this.filterCourse = '';
    }
    const keyword = this.searchText.trim().toLowerCase();
    const list = filterItems((item: TodoItem): boolean => {
      if (this.filterType >= 0 && item.type !== this.filterType) {
        return false;
      }
      if (this.filterCourse !== '' && item.course !== this.filterCourse) {
        return false;
      }
      if (this.filterStatus >= 0 && (item.done || item.submitted) !== (this.filterStatus === 1)) {
        return false;
      }
      if (keyword !== '') {
        const inText = item.text.toLowerCase().includes(keyword);
        const inCourse = (item.course ?? '').toLowerCase().includes(keyword);
        if (!inText && !inCourse) {
          return false;
        }
      }
      return true;
    });
    list.sort((a: IndexedTodoItem, b: IndexedTodoItem): number =>
      getEffectiveTime(a.item) - getEffectiveTime(b.item));
    this.todoList = list;
  }

  /** 从默认学期课表中读取课程名列表（去重），供编辑弹窗快速填写 */
  loadCourseNames(): void {
    const names: string[] = [];
    try {
      const semester = ScheduleManager.semesters[ScheduleManager.defaultSemester];
      const courses = ScheduleStorage.getCourses(semester.createTime);
      courses.forEach((c: classAttribute): void => {
        if (c.name !== '' && !names.includes(c.name)) {
          names.push(c.name);
        }
      });
    } catch (e) {
      console.error('Todo: failed to load course names:', JSON.stringify(e));
    }
    this.courseNames = names;
  }

  pad2(value: number): string {
    return value.toString().padStart(2, '0');
  }

  /** 毫秒时间戳 → 'M-d HH:mm' */
  formatTime(ts: number): string {
    const d = new Date(ts);
    return `${d.getMonth() + 1}-${d.getDate()} ${this.pad2(d.getHours())}:${this.pad2(d.getMinutes())}`;
  }

  /** 'yyyy-MM-dd' + 时分 → 毫秒时间戳 */
  buildTime(date: string, hour: number, minute: number): number {
    const parts = date.split('-');
    return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]),
      hour, minute, 0).getTime();
  }

  /** 打开新建/编辑弹窗 */
  openEditor(indexed?: IndexedTodoItem): void {
    const today = new Date();
    const todayStr = `${today.getFullYear()}-${this.pad2(today.getMonth() + 1)}-${this.pad2(today.getDate())}`;
    this.draftBeginDate = todayStr;
    this.draftEndDate = todayStr;
    this.beginHour = today.getHours();
    this.beginMinute = 0;
    this.endHour = today.getHours() + 2 > 23 ? 23 : today.getHours() + 2;
    this.endMinute = 0;
    this.draftChannels = [false, false, false, false, false];
    this.draftImages = [];
    if (indexed === undefined) {
      this.editingIndex = -1;
      this.draftType = TodoType.Todo;
      this.draftText = '';
      this.draftCourse = '';
      this.draftBeginDisabled = true;
      this.draftEndDisabled = true;
      this.draftPriority = DEFAULT_PRIORITY;
    } else {
      const item = indexed.item;
      this.editingIndex = indexed.index;
      this.draftType = item.type;
      this.draftText = item.text;
      this.draftCourse = item.course ?? '';
      this.draftPriority = item.priority ?? DEFAULT_PRIORITY;
      this.draftImages = (item.imagePaths ?? []).map((path: string): DraftImage => {
        return { uri: fileUri.getUriFromPath(path), path: path };
      });
      if (item.type === TodoType.Assignment) {
        this.draftEndDisabled = item.ddl === undefined;
        this.draftBeginDisabled = true;
        if (item.ddl !== undefined) {
          const d = new Date(item.ddl);
          this.draftEndDate = `${d.getFullYear()}-${this.pad2(d.getMonth() + 1)}-${this.pad2(d.getDate())}`;
          this.endHour = d.getHours();
          this.endMinute = d.getMinutes();
        }
        (item.channels ?? []).forEach((ch: SubmitChannel) => {
          this.draftChannels[ch] = true;
        });
      } else {
        this.draftBeginDisabled = item.beginTime === undefined;
        this.draftEndDisabled = item.endTime === undefined;
        if (item.beginTime !== undefined) {
          const d = new Date(item.beginTime);
          this.draftBeginDate = `${d.getFullYear()}-${this.pad2(d.getMonth() + 1)}-${this.pad2(d.getDate())}`;
          this.beginHour = d.getHours();
          this.beginMinute = d.getMinutes();
        }
        if (item.endTime !== undefined) {
          const d = new Date(item.endTime);
          this.draftEndDate = `${d.getFullYear()}-${this.pad2(d.getMonth() + 1)}-${this.pad2(d.getDate())}`;
          this.endHour = d.getHours();
          this.endMinute = d.getMinutes();
        }
      }
    }
    this.draftTypeIndexes = [this.draftType];
    this.showSheet = true;
  }

  /** 组装草稿为 TodoItem；时间未启用的字段返回 undefined */
  buildDraftItem(): TodoItem {
    const item: TodoItem = {
      type: this.draftType,
      text: this.draftText.trim(),
      done: false,
      submitted: false,
      channels: []
    };
    if (this.draftCourse.trim() !== '') {
      item.course = this.draftCourse.trim();
    }
    if (this.draftType === TodoType.Assignment) {
      if (!this.draftEndDisabled) {
        item.ddl = this.buildTime(this.draftEndDate, this.endHour, this.endMinute);
      }
      item.channels = CHANNEL_NAMES
        .map((_: string, i: number): SubmitChannel => i as SubmitChannel)
        .filter((ch: SubmitChannel): boolean => this.draftChannels[ch]);
      item.submitted = false;
    } else {
      if (!this.draftBeginDisabled) {
        item.beginTime = this.buildTime(this.draftBeginDate, this.beginHour, this.beginMinute);
      }
      if (!this.draftEndDisabled) {
        item.endTime = this.buildTime(this.draftEndDate, this.endHour, this.endMinute);
      }
    }
    item.priority = this.draftPriority;
    // 附图：已保存的路径 + 本次新选取（保存时导入私有目录）
    const paths: string[] = [];
    this.draftImages.forEach((img: DraftImage): void => {
      if (img.path !== undefined) {
        paths.push(img.path);
      } else {
        const imported = importImage(new fileUri.FileUri(img.uri).path);
        if (imported !== '') {
          paths.push(imported);
        }
      }
    });
    if (paths.length > 0) {
      item.imagePaths = paths;
    }
    return item;
  }

  /** 校验开始时间不晚于截止时间，违反时将二者互换（日期、时、分） */
  normalizeDraftTimes(): void {
    if (this.draftType !== TodoType.Todo ||
      this.draftBeginDisabled || this.draftEndDisabled) {
      return;
    }
    const begin = this.buildTime(this.draftBeginDate, this.beginHour, this.beginMinute);
    const end = this.buildTime(this.draftEndDate, this.endHour, this.endMinute);
    if (begin > end) {
      const tmpDate = this.draftBeginDate;
      const tmpHour = this.beginHour;
      const tmpMinute = this.beginMinute;
      this.draftBeginDate = this.draftEndDate;
      this.beginHour = this.endHour;
      this.beginMinute = this.endMinute;
      this.draftEndDate = tmpDate;
      this.endHour = tmpHour;
      this.endMinute = tmpMinute;
    }
  }

  saveDraft(): void {
    if (this.draftText.trim() === '') {
      return;
    }
    this.normalizeDraftTimes();
    const newItem = this.buildDraftItem();
    if (this.editingIndex >= 0) {
      updateItem(this.editingIndex, newItem);
    } else {
      addItem(newItem);
    }
    this.showSheet = false;
    this.refresh();
  }

  confirmDelete(): void {
    this.msgDialogController = new CustomDialogController({
      builder: MessageDialog({
        message: '确定删除这条内容吗？',
        onConfirm: () => {
          if (this.editingIndex >= 0) {
            removeItem(this.editingIndex);
          }
          this.showSheet = false;
          this.refresh();
        }
      }),
      autoCancel: true,
      gridCount: 4
    });
    this.msgDialogController.open();
  }

  /** 显式复制一条 TodoItem（ArkTS 禁用 Object.assign 与无类型对象字面量） */
  copyItem(item: TodoItem): TodoItem {
    return {
      type: item.type,
      text: item.text,
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

  /** 切换完成状态 */
  toggleDone(indexed: IndexedTodoItem): void {
    const item = this.copyItem(indexed.item);
    item.done = !item.done;
    updateItem(indexed.index, item);
    this.refresh();
  }

  toggleSubmitted(indexed: IndexedTodoItem): void {
    const item = this.copyItem(indexed.item);
    item.submitted = !item.submitted;
    updateItem(indexed.index, item);
    this.refresh();
  }

  /** 选取相册图片作为附图（可多选）；不立即复制，保存草稿时才导入私有目录 */
  async pickImage(): Promise<void> {
    try {
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 9;
      const picker = new photoAccessHelper.PhotoViewPicker();
      const result = await picker.select(options);
      if (result.photoUris.length > 0) {
        const picked = result.photoUris.map((uri: string): DraftImage => {
          return { uri: uri };
        });
        this.draftImages = this.draftImages.concat(picked);
      }
    } catch (e) {
      console.error('Todo: pickImage failed:', JSON.stringify(e));
    }
  }

  /** 移除草稿中的一张附图；已保存文件在 updateItem 时清理 */
  removeImage(index: number): void {
    this.draftImages = this.draftImages.filter((_: DraftImage, i: number): boolean => i !== index);
  }

  /** 重要度对应的徽章底色，数值越高越醒目 */
  priorityColor(priority: number): Resource {
    if (priority >= 7) {
      return $r('app.color.minute');
    }
    if (priority >= 4) {
      return $r('app.color.hour');
    }
    return $r('app.color.green');
  }

  /** 条目的时间描述文本 */
  timeDescription(item: TodoItem): string {
    if (item.type === TodoType.Assignment) {
      return item.ddl !== undefined ? `截止时间 ${this.formatTime(item.ddl)}` : '';
    }
    const parts: string[] = [];
    if (item.beginTime !== undefined) {
      parts.push(`始 ${this.formatTime(item.beginTime)}`);
    }
    if (item.endTime !== undefined) {
      parts.push(`止 ${this.formatTime(item.endTime)}`);
    }
    return parts.join('  ');
  }

  /** 课程筛选下拉的选项（首项为“全部课程”） */
  filterSelectOptions(): SelectOption[] {
    const options: SelectOption[] = [{ value: '全部课程' } as SelectOption];
    this.filterCourseNames.forEach((name: string): void => {
      options.push({ value: name } as SelectOption);
    });
    return options;
  }

  /** 课表课程下拉的选项（首项为“不指定课程”） */
  courseSelectOptions(): SelectOption[] {
    const options: SelectOption[] = [{ value: '不指定课程' } as SelectOption];
    this.courseNames.forEach((name: string): void => {
      options.push({ value: name } as SelectOption);
    });
    return options;
  }

  /** 类型筛选下拉的选项 */
  typeSelectOptions(): SelectOption[] {
    return [{ value: '全部类型' }, { value: '待办' },
      { value: '作业' }] as SelectOption[];
  }

  /** 状态筛选下拉的选项 */
  statusSelectOptions(): SelectOption[] {
    return [{ value: '全部状态' }, { value: '未完成' },
      { value: '已完成' }] as SelectOption[];
  }

  /** 是否启用了任意过滤/搜索条件（用于空态文案区分） */
  hasFilterCondition(): boolean {
    return this.searchText.trim() !== '' || this.filterType >= 0 ||
      this.filterCourse !== '' || this.filterStatus >= 0;
  }

  @Builder
  todoCard(indexed: IndexedTodoItem) {
    Row({ space: 12 }) {
      // 完成状态：紧凑圆形勾选，替代原先占位的“完成”按钮

      Checkbox()
        .select(indexed.item.done)
        .selectedColor(presetColor[BackgroundImage.themeColor].accentColor)
        .onChange((value: boolean) => {
          this.toggleDone(indexed);
        });

      Column({ space: 5 }) {
        // 标题行：正文为主，课程名作为前置小标签
        Text() {
          if (indexed.item.course) {
            Span(indexed.item.course)
              .fontColor(presetColor[BackgroundImage.themeColor].accentColor)
              // .padding({ left: 6, right: 6, top: 1, bottom: 1 })
              // .borderRadius(4)
              // .backgroundColor($r('app.color.list_item_count_background'))
            Span('  ')
          }
          Span(indexed.item.text)
            .fontWeight(indexed.item.done ? FontWeight.Normal : FontWeight.Medium)
            .decoration({
              type: indexed.item.done ? TextDecorationType.LineThrough : TextDecorationType.None,
              color: $r('app.color.transparent_text')
            })
        }
        .fontSize(15)

        // 信息行：时间与徽章同行，左对齐
        Row({ space: 8 }) {
          if ((indexed.item.priority !== undefined && indexed.item.priority > 0) ||
            indexed.item.type === TodoType.Assignment) {
            Row({ space: 4 }) {
              if (indexed.item.type === TodoType.Assignment) {
                Text('作业')
                  .fontSize(10)
                  .fontColor($r('app.color.transparent_text'))
                  .padding({ left: 6, right: 6, top: 1, bottom: 1 })
                  .borderRadius(4)
                  .backgroundColor($r('app.color.list_item_count_background'))
              }
              if (indexed.item.priority !== undefined && indexed.item.priority > 0) {
                Text(`重要度 ${indexed.item.priority}`)
                  .fontSize(10)
                  .fontColor(Color.White)
                  .padding({ left: 6, right: 6, top: 1, bottom: 1 })
                  .borderRadius(4)
                  .backgroundColor(this.priorityColor(indexed.item.priority))
              }
            }
          }

          if (this.timeDescription(indexed.item) !== '') {
            Text(this.timeDescription(indexed.item))
              .fontSize(12)
              .fontColor(!indexed.item.done && getEffectiveTime(indexed.item) <= Date.now() ?
                $r('app.color.red') : $r('app.color.normal_text'))
          }

          // 作业渠道：紧凑文字，弱化描边
          if (indexed.item.type === TodoType.Assignment && indexed.item.channels.length > 0) {
            Text(indexed.item.channels
              .map((ch: SubmitChannel): string => CHANNEL_NAMES[ch])
              .join(' / '))
              .fontSize(11)
              .fontColor(presetColor[BackgroundImage.themeColor].accentColor)
              .opacity(0.85)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .width('100%')

        if (indexed.item.imagePaths !== undefined && indexed.item.imagePaths.length > 0) {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(indexed.item.imagePaths, (path: string) => {
              Image(fileUri.getUriFromPath(path))
                .width(72)
                .height(72)
                .objectFit(ImageFit.Cover)
                .borderRadius(8)
                .draggable(false)
                .autoResize(true)
                .margin({ right: 6, top: 2 })
            }, (path: string) => path)
          }
          .width('100%')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 作业提交：右侧竖排状态标记，避免与主信息抢视线
      if (indexed.item.type === TodoType.Assignment) {
        Column() {
          Text(indexed.item.submitted ? '已提交' : '未提交')
            .fontSize(11)
            .fontColor(indexed.item.submitted ?
              presetColor[BackgroundImage.themeColor].accentColor : $r('app.color.transparent_text'))
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(6)
            .border({
              width: 1,
              color: indexed.item.submitted ?
                presetColor[BackgroundImage.themeColor].accentColor : $r('app.color.transparent_text')
            })
        }
        .onClick(() => this.toggleSubmitted(indexed))
      }
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .borderRadius(16)
    .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
    .backgroundBlurStyle(BackgroundImage.blurLevel)
    .onClick(() => this.openEditor(indexed))
  }

  @Builder
  editorSheet() {
    Column() {
      Row({ space: 5 }) {
        Text(this.editingIndex >= 0 ? '编辑日程' : '新建日程')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .margin({ left: 8 })

        if (this.editingIndex >= 0) {
          Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
            Image($r('app.media.trash_red'))
              .width(24)
              .height(24)
              .draggable(false)
          }
          .width(42)
          .height(42)
          .onClick(() => this.confirmDelete())
        }

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.close'))
            .width(24)
            .height(24)
            .draggable(false)
        }
        .width(42)
        .height(42)
        .onClick(() => {
          this.showSheet = false;
        })

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image(this.editingIndex >= 0 ? $r('app.media.save') : $r('app.media.checkmark'))
            .width(24)
            .height(24)
            .draggable(false)
        }
        .width(42)
        .height(42)
        .onClick(() => this.saveDraft())
      }
      .width('100%')
      .margin({ bottom: 10 })

      Scroll() {
        Column() {
          // 类型切换
          Row() {
            Text('类型：')
            Row() {
              SegmentButton({
                options: this.draftTypeOptions,
                selectedIndexes: $draftTypeIndexes,
                onItemClicked: (index: number) => {
                  this.draftType = index as TodoType;
                }
              })
            }
            .layoutWeight(1)
          }
          .margin({ bottom: 5 })

          // 内容
          Row() {
            Text('内容：')
            TextArea({ text: this.draftText })
              .maxLines(6)
              .layoutWeight(1)
              .onChange((input: string) => {
                this.draftText = input;
              })
          }
          .margin({ bottom: 5 })

          // 课程分类
          Row() {
            Text('课程：')
            TextInput({ text: this.draftCourse })
              .margin({ right: 5 })
              .layoutWeight(1)
              .onChange((input: string) => {
                this.draftCourse = input;
              })
            Select(this.courseSelectOptions())
              .selected(this.draftCourse === '' ? 0 : this.courseNames.indexOf(this.draftCourse) + 1)
              .value('选择课程')
              .onSelect((index: number) => {
                this.draftCourse = index === 0 ? '' : this.courseNames[index - 1];
              })
          }
          .margin({ bottom: 5 })

          // 重要度
          Row() {
            Text('重要度')
            Slider({ min: 0, max: MAX_PRIORITY, value: this.draftPriority, step: 1, style: SliderStyle.InSet })
              .showSteps(true)
              .selectedColor(presetColor[BackgroundImage.themeColor].accentColor)
              .layoutWeight(1)
              .onChange((value: number) => {
                this.draftPriority = Math.round(value);
              })
            Text(`${this.draftPriority}`)
              .width(24)
              .textAlign(TextAlign.Center)
          }
          .margin({ bottom: 5 })

          // 附图
          Column({ space: 5 }) {
            Row() {
              Text('附图')
              Button('选择图片')
                .fontSize(13)
                .height(32)
                .onClick(() => this.pickImage())
                .backgroundColor(presetColor[BackgroundImage.themeColor].accentColor)
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)

            if (this.draftImages.length > 0) {
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.draftImages, (img: DraftImage, index: number) => {
                  Stack({ alignContent: Alignment.TopEnd }) {
                    Image(img.uri)
                      .width(80)
                      .height(80)
                      .objectFit(ImageFit.Cover)
                      .borderRadius(12)
                      .draggable(false)
                      .autoResize(true)
                      .onClick(() => ImagePreview.show(
                        this.draftImages.map((d: DraftImage): string => d.uri),
                        {
                          startIndex: index,
                          showIndex: true,
                          closeOnClickImage: false
                        }))
                    Text('󰁖')
                      .fontSize(14)
                      .fontColor(Color.White)
                      .width(24)
                      .height(24)
                      .textAlign(TextAlign.Center)
                      .borderRadius(12)
                      .backgroundColor($r('sys.color.mask_secondary'))
                      .onClick(() => this.removeImage(index))
                  }
                  .margin({ right: 8, bottom: 8 })
                }, (img: DraftImage) => img.uri)
              }
              .width('100%')
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .margin({ bottom: 5 })

          if (this.draftType === TodoType.Todo) {
            // 待办：开始时间
            Row() {
              Text($r('app.string.start_time_colon'))
                .layoutWeight(1)
              Toggle({ type: ToggleType.Checkbox, isOn: this.draftBeginDisabled })
                .selectedColor(presetColor[BackgroundImage.themeColor].accentColor)
                .onChange((isOn: boolean) => {
                  this.draftBeginDisabled = isOn;
                })
              Text($r('app.string.not_specify'))
            }

            Row() {
              Text(this.draftBeginDate)
                .onClick(() => this.pickDate(false))
              CounterComponent({
                options: {
                  type: CounterType.INLINE,
                  inlineOptions: {
                    value: this.beginHour,
                    min: 0,
                    step: 1,
                    max: 23,
                    textWidth: 25,
                    onChange: (value: number) => {
                      this.beginHour = value;
                    }
                  }
                }
              })
              Text(' : ')
              CounterComponent({
                options: {
                  type: CounterType.INLINE,
                  inlineOptions: {
                    value: this.beginMinute,
                    min: 0,
                    step: 1,
                    max: 59,
                    textWidth: 25,
                    onChange: (value: number) => {
                      this.beginMinute = value;
                    }
                  }
                }
              })
            }
            .width('100%')
            .margin({ bottom: 5 })
            .visibility(this.draftBeginDisabled ? Visibility.None : Visibility.Visible)

            // 待办：截止时间
            Row() {
              Text($r('app.string.end_time_colon'))
                .layoutWeight(1)
              Toggle({ type: ToggleType.Checkbox, isOn: this.draftEndDisabled })
                .selectedColor(presetColor[BackgroundImage.themeColor].accentColor)
                .onChange((isOn: boolean) => {
                  this.draftEndDisabled = isOn;
                })
              Text($r('app.string.not_specify'))
            }

            Row() {
              Text(this.draftEndDate)
                .onClick(() => this.pickDate(true))
              CounterComponent({
                options: {
                  type: CounterType.INLINE,
                  inlineOptions: {
                    value: this.endHour,
                    min: 0,
                    step: 1,
                    max: 23,
                    textWidth: 25,
                    onChange: (value: number) => {
                      this.endHour = value;
                    }
                  }
                }
              })
              Text(' : ')
              CounterComponent({
                options: {
                  type: CounterType.INLINE,
                  inlineOptions: {
                    value: this.endMinute,
                    min: 0,
                    step: 1,
                    max: 59,
                    textWidth: 25,
                    onChange: (value: number) => {
                      this.endMinute = value;
                    }
                  }
                }
              })
            }
            .visibility(this.draftEndDisabled ? Visibility.None : Visibility.Visible)
            .width('100%')
          } else {
            // 作业：DDL
            Row() {
              Text('截止时间')
                .layoutWeight(1)
              Toggle({ type: ToggleType.Checkbox, isOn: this.draftEndDisabled })
                .selectedColor(presetColor[BackgroundImage.themeColor].accentColor)
                .onChange((isOn: boolean) => {
                  this.draftEndDisabled = isOn;
                })
              Text($r('app.string.not_specify'))
            }

            Row() {
              Text(this.draftEndDate)
                .onClick(() => this.pickDate(true))
              CounterComponent({
                options: {
                  type: CounterType.INLINE,
                  inlineOptions: {
                    value: this.endHour,
                    min: 0,
                    step: 1,
                    max: 23,
                    textWidth: 25,
                    onChange: (value: number) => {
                      this.endHour = value;
                    }
                  }
                }
              })
              Text(' : ')
              CounterComponent({
                options: {
                  type: CounterType.INLINE,
                  inlineOptions: {
                    value: this.endMinute,
                    min: 0,
                    step: 1,
                    max: 59,
                    textWidth: 25,
                    onChange: (value: number) => {
                      this.endMinute = value;
                    }
                  }
                }
              })
            }
            .width('100%')
            .margin({ bottom: 5 })
            .visibility(this.draftEndDisabled ? Visibility.None : Visibility.Visible)

            // 作业：提交渠道多选
            Column() {
              Text($r('app.string.submit_channel'))
                .margin({ bottom: 5 })
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(CHANNEL_NAMES, (name: string, index: number) => {
                  Row() {
                    Checkbox({ name: `todo_channel_${index}` })
                      .shape(CheckBoxShape.ROUNDED_SQUARE)
                      .select(this.draftChannels[index])
                      .selectedColor(presetColor[BackgroundImage.themeColor].accentColor)
                      .onChange((isOn: boolean) => {
                        this.draftChannels[index] = isOn;
                      })
                    Text(name)
                      .fontSize(14)
                  }
                  .margin({ right: 16, bottom: 4 })
                })
              }
              .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('90%')
        .margin({ bottom: 16 })
      }
      .fadingEdge(true)
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false });
    }
    .width('100%')
    .height('100%')
    .padding({ top: 16, left: 16, right: 16 })
  }

  /** target 为 true 时修改截止日期，false 时修改开始日期 */
  pickDate(target: boolean): void {
    const current = target ? this.draftEndDate : this.draftBeginDate;
    const parts = current.split('-');
    DatePickerDialog.show({
      selected: new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2])),
      onDateAccept: (value: Date) => {
        const picked =
          `${value.getFullYear()}-${this.pad2(value.getMonth() + 1)}-${this.pad2(value.getDate())}`;
        if (target) {
          this.draftEndDate = picked;
        } else {
          this.draftBeginDate = picked;
        }
      }
    });
  }

  menuItems: Array<NavigationMenuItem> = [
    {
      value: '新建',
      icon: $r('app.media.plus_square'),
      action: () => {
        this.openEditor();
      }
    }
  ];

  build() {
    NavDestination() {
      Column() {
        Column({ space: 8 }) {
          // 搜索框 + 筛选栏开关
          Row({ space: 8 }) {
            Search({ placeholder: '搜索内容或课程' })
              .margin(0)
              .layoutWeight(1)
              .onChange((input: string) => {
                this.searchText = input;
                if (this.searchDebounceTimer !== null) {
                  clearTimeout(this.searchDebounceTimer);
                }
                this.searchDebounceTimer = setTimeout(() => {
                  this.refresh();
                }, 500);
              })
            Toggle({ type: ToggleType.Button, isOn: this.showFilter }) {
              Image($r('app.media.filter'))
                .width(22)
                .height(22)
            }
            .width(40)
            .height(40)
            // .selectedColor(presetColor[BackgroundImage.themeColor].accentColor)
            .onChange((isOn: boolean) => this.getUIContext().animateTo({ duration: 200 }, () => { this.showFilter = isOn; }))
          }
          .width('100%')

          if (this.showFilter) {
            Row({ space: 8 }) {
              Select(this.typeSelectOptions())
                .selected(this.filterType + 1)
                .value(this.filterType === -1 ? '全部类型' :
                  (this.filterType === TodoType.Todo ? '待办' : '作业'))
                .fontColor(presetColor[BackgroundImage.themeColor].accentColor)
                .selectedOptionFontColor(presetColor[BackgroundImage.themeColor].accentColor)
                .layoutWeight(1)
                .onSelect((index: number) => {
                  this.filterType = index - 1;
                  this.refresh();
                })
              if (this.filterCourseNames.length > 0) {
                Select(this.filterSelectOptions())
                  .selected(this.filterCourse === '' ? 0 : this.filterCourseNames.indexOf(this.filterCourse) + 1)
                  .value(this.filterCourse === '' ? '全部课程' : this.filterCourse)
                  .fontColor(presetColor[BackgroundImage.themeColor].accentColor)
                  .selectedOptionFontColor(presetColor[BackgroundImage.themeColor].accentColor)
                  .layoutWeight(1)
                  .onSelect((index: number) => {
                    this.filterCourse = index === 0 ? '' : this.filterCourseNames[index - 1];
                    this.refresh();
                  })
              }
              Select(this.statusSelectOptions())
                .selected(this.filterStatus + 1)
                .value(this.filterStatus === -1 ? '全部状态' :
                  (this.filterStatus === 0 ? '未完成' : '已完成'))
                .fontColor(presetColor[BackgroundImage.themeColor].accentColor)
                .selectedOptionFontColor(presetColor[BackgroundImage.themeColor].accentColor)
                .layoutWeight(1)
                .onSelect((index: number) => {
                  this.filterStatus = index - 1;
                  this.refresh();
                })
            }
            .width('100%')
          }
        }
        .padding(8)
        .borderRadius(28)
        .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
        .backgroundBlurStyle(BackgroundImage.blurLevel)
        .width('100%')

        if (this.todoList.length === 0) {
          Column() {
            Column() {
              Image($r('app.media.heavy_task'))
                .width(128)
                .interpolation(ImageInterpolation.Medium)
                .draggable(false)
                .margin({ bottom: 6 })
              Text(this.hasFilterCondition() ? $r('app.string.no_search_result') : $r('app.string.no_todo_info2'))
                .fontSize(18)
                .textAlign(TextAlign.Center)
            }
            .justifyContent(FlexAlign.Center)
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
          .height('70%')
          .justifyContent(FlexAlign.Center);
        } else {
          List({ space: 8 }) {
            ForEach(this.todoList, (indexed: IndexedTodoItem) => {
              ListItem() {
                this.todoCard(indexed)
              }
            })
          }
          .width('100%')
          .margin({ top: 8 })
          .borderRadius({ topLeft: 16, topRight: 16 })
          .layoutWeight(1)
          .alignListItem(ListItemAlign.Center)
          .scrollBar(BarState.Auto)
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
          .contentEndOffset(12)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
        }
      }
      .height('100%')
      .width('100%')
      .padding({ left: 12, right: 12, top: 12 })
      .bindSheet($$this.showSheet, this.editorSheet(), {
        detents: [SheetSize.MEDIUM, SheetSize.LARGE],
        preferType: SheetType.CENTER,
        showClose: false,
        scrollSizeMode: ScrollSizeMode.CONTINUOUS,
        backgroundColor: '#0000',
        blurStyle: BlurStyle.Regular
      })
    }
    .title({ main: $r('app.string.todo_card_title'), sub: '尝鲜版' }, {
      backgroundBlurStyle: BackgroundImage.blurLevel,
      backgroundColor: BackgroundImage.blurLevel === undefined ? BackgroundImage.titleBackgroundColor : undefined
    })
    .backButtonIcon($r('app.media.close'))
    .menus(this.menuItems)
    .backgroundColor(BackgroundImage.showImage ? Color.Transparent : $r('app.color.normal_background'))
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
      this.loadCourseNames();
      this.refresh();
    })
  }
}
