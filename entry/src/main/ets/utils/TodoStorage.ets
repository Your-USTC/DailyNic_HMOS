import { fileIo } from '@kit.CoreFileKit';

/**
 * 待办管理器数据模型与本地存储。
 * 待办事项与作业统一存放在 todoData.json 中，通过 type 字段区分。
 * 条目不使用唯一 id，数组下标即为其标识；过滤/排序结果通过 IndexedTodoItem
 * 携带原始下标，便于随后调用 updateItem / removeItem 定位原始条目。
 */

/** 条目类型 */
export enum TodoType {
  /** 普通待办事项 */
  Todo = 0,
  /** 作业 */
  Assignment = 1
}

/** 作业提交渠道，可多选 */
export enum SubmitChannel {
  /** BB 平台 */
  Blackboard = 0,
  /** QQ */
  QQ = 1,
  /** 邮箱 */
  Email = 2,
  /** 线上（其他线上平台） */
  Online = 3,
  /** 线下 */
  Offline = 4
}

export interface TodoItem {
  /** 条目类型：待办事项 / 作业 */
  type: TodoType,
  /** 条目文字内容 */
  text: string,
  /** 补充描述（可省略表示未填写） */
  description?: string,
  /** 课程分类名（可省略表示未分类） */
  course?: string,
  /** 待办开始时间（毫秒时间戳），可省略表示不限 */
  beginTime?: number,
  /** 待办结束时间（毫秒时间戳），可省略表示不限 */
  endTime?: number,
  /** 作业 DDL（毫秒时间戳），仅作业类型有意义，可省略 */
  ddl?: number,
  /** 是否已完成 */
  done: boolean,
  /** 是否已提交，仅作业类型有意义 */
  submitted: boolean,
  /** 已提交的渠道列表（可多选），仅作业类型有意义 */
  channels: SubmitChannel[],
  /** 重要度 0-10，数值越大越重要；可省略表示未设置（默认按 5 处理） */
  priority?: number,
  /** 附图在应用私有目录中的绝对路径列表；可省略或空数组表示无附图 */
  imagePaths?: string[]
}

/** 过滤/排序结果：index 为条目在原始数组中的下标 */
export interface IndexedTodoItem {
  index: number,
  item: TodoItem
}

/** 未设置时间的条目在升序排序中排到最后 */
const UNSET_TIME = Number.MAX_SAFE_INTEGER;

/** 未设置重要度时采用的默认值，与课表模块保持一致 */
export const DEFAULT_PRIORITY = 5;
/** 重要度取值上限（Slider 0-10） */
export const MAX_PRIORITY = 10;

let todoFilePath: string = '';
let todoImageDir: string = '';
let todoCache: TodoItem[] | null = null;

/**
 * 初始化 TodoStorage。必须在任何读写操作之前调用一次（EntryAbility.onCreate 中调用）。
 * @param context 应用上下文
 */
export function init(context: Context): void {
  todoFilePath = `${context.filesDir}/todoData.json`;
  todoImageDir = `${context.filesDir}/todoImages`;
  try {
    if (!fileIo.accessSync(todoImageDir)) {
      fileIo.mkdirSync(todoImageDir);
    }
  } catch (e) {
    console.error('TodoStorage: failed to create image dir:', JSON.stringify(e));
  }
  loadTodo();
}

/**
 * 将外部图片（相册选取后得到的文件路径）复制到应用私有目录。
 * @param srcPath 源图片的文件系统路径
 * @returns 复制后的私有目录绝对路径；失败返回空串
 */
export function importImage(srcPath: string): string {
  if (srcPath === '') {
    return '';
  }
  try {
    const dest = `${todoImageDir}/todo_${Date.now()}_${Math.floor(Math.random() * 1e6)}`;
    fileIo.copyFileSync(srcPath, dest);
    return dest;
  } catch (e) {
    console.error('TodoStorage: failed to import image:', JSON.stringify(e));
    return '';
  }
}

/** 删除私有目录中的附图文件；路径为空或文件不存在时静默忽略 */
export function deleteImage(path: string): void {
  if (path === '') {
    return;
  }
  try {
    if (fileIo.accessSync(path)) {
      fileIo.unlinkSync(path);
    }
  } catch (e) {
    console.error('TodoStorage: failed to delete image:', JSON.stringify(e));
  }
}

function loadTodo(): TodoItem[] {
  if (todoCache !== null) {
    return todoCache;
  }
  try {
    if (fileIo.accessSync(todoFilePath)) {
      const parsed = JSON.parse(fileIo.readTextSync(todoFilePath)) as TodoItem[];
      if (Array.isArray(parsed)) {
        todoCache = parsed;
      }
    }
  } catch (e) {
    console.error('TodoStorage: failed to load todo file:', JSON.stringify(e));
  }
  if (todoCache === null) {
    todoCache = [];
  }
  return todoCache;
}

function flushTodo(): void {
  try {
    const file = fileIo.openSync(todoFilePath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    fileIo.writeSync(file.fd, JSON.stringify(todoCache ?? []));
    fileIo.closeSync(file);
  } catch (e) {
    console.error('TodoStorage: failed to save todo file:', JSON.stringify(e));
  }
}

export function getItems(): TodoItem[] {
  return loadTodo();
}

export function setItems(data: TodoItem[]): void {
  todoCache = data;
  flushTodo();
}

/** 在数组末尾追加一条待办/作业 */
export function addItem(item: TodoItem): void {
  loadTodo().push(item);
  flushTodo();
}

/** 按数组下标更新一条待办/作业；下标越界时静默忽略。清理不再引用的旧附图文件 */
export function updateItem(index: number, item: TodoItem): void {
  const data = loadTodo();
  if (index < 0 || index >= data.length) {
    return;
  }
  const old = data[index];
  if (old.imagePaths !== undefined) {
    const kept = item.imagePaths ?? [];
    old.imagePaths.forEach((path: string): void => {
      if (!kept.includes(path)) {
        deleteImage(path);
      }
    });
  }
  data[index] = item;
  flushTodo();
}

/** 按数组下标删除一条待办/作业；下标越界时静默忽略。删除后其余条目下标前移，同时清理其附图 */
export function removeItem(index: number): void {
  const data = loadTodo();
  if (index < 0 || index >= data.length) {
    return;
  }
  const removed = data[index];
  removed.imagePaths?.forEach((path: string): void => deleteImage(path));
  data.splice(index, 1);
  flushTodo();
}

/**
 * 清除全部待办数据（用于故障恢复页面）。
 */
export function clearTodoData(): void {
  todoCache = [];
  flushTodo();
}

/**
 * 按条件过滤条目，结果携带原始数组下标，便于随后调用 updateItem / removeItem。
 */
export function filterItems(predicate: (item: TodoItem) => boolean): IndexedTodoItem[] {
  const data = loadTodo();
  const result: IndexedTodoItem[] = [];
  for (let i = 0; i < data.length; i++) {
    if (predicate(data[i])) {
      result.push({ index: i, item: data[i] });
    }
  }
  return result;
}

/** 过滤出所有未完成的条目 */
export function getUnfinished(): IndexedTodoItem[] {
  return filterItems((item: TodoItem): boolean => !item.done);
}

/** 过滤出指定类型（待办事项 / 作业）的条目 */
export function getByType(type: TodoType): IndexedTodoItem[] {
  return filterItems((item: TodoItem): boolean => item.type === type);
}

/** 过滤出指定时间点（毫秒时间戳）之前到期且未完成的条目 */
export function getOverdue(timestamp: number): IndexedTodoItem[] {
  return filterItems((item: TodoItem): boolean =>
    !item.done && getEffectiveTime(item) <= timestamp);
}

/**
 * 条目的有效时间：待办优先取开始时间，其次结束时间；作业取 DDL。
 * 均未设置时返回 UNSET_TIME（排序时排在最后）。
 */
export function getEffectiveTime(item: TodoItem): number {
  return item.beginTime ?? item.endTime ?? item.ddl ?? UNSET_TIME;
}

/**
 * 按有效时间原地排序（未设置时间的条目在升序时排到最后）。
 * @param items 条目数组（如 getItems() 的返回值）
 * @param ascending 是否升序，默认 true
 */
export function sortItems(items: TodoItem[], ascending: boolean = true): void {
  items.sort((a: TodoItem, b: TodoItem): number => {
    const timeA = getEffectiveTime(a);
    const timeB = getEffectiveTime(b);
    return ascending ? timeA - timeB : timeB - timeA;
  });
}
