
import UnifiedPreferences, { LAST_DAY_KEY, TOTAL_DAYS_KEY, CONSECUTIVE_DAYS_KEY, CONTENT_KEY, millisecondsPerWeek } from '../utils/UnifyPreference';
import ScheduleManager from './Classes/ScheduleManager';
import * as ExamStorage from './ExamStorage';
import { i18n } from '@kit.LocalizationKit';

// 主题签到词分组：CHECK_IN_CONTENT_LIST 与 THEME_INDICES 均由 THEMED_SECTIONS 生成
interface ThemedSection {
  key: string;        // 主题标识：公历节日为 'MM-dd'，农历节日为 'l-农历月-农历日'（农历月从0计），除夕为 'l-eve'，其余为固定主题名
  name: string;       // 主题名称（如 '国庆节'），供 getSpecialDateToday 返回
  contents: string[]; // 主题签到词
}

export class CheckInTools {
  // —— 通用签到词（下标 0~49 保持不变，与已收集记录兼容）——
  private static readonly BASE_CONTENT_LIST: string[] = [
    '呐呐，作业写完了吗？该不会是…一个字都没动吧？噗——真是活该！', // 0
    '喂！早饭吃了吗？不会又饿着肚子吧？要是低血糖晕倒了，我可不会去医务室看你这种不爱惜自己的杂鱼的！',
    '这么晚了还不睡呀？我是该为深夜偶遇而高兴，还是担心你作息不健康？',
    '诶？这就签到了吗？还以为你会直接睡过头呢…勉强表扬你一下！',
    '早安可是很重要的，要再认真点！跟我念——早，上，好！早上好哦！',
    '啊啦啦~脸色好差呢，昨晚又熬夜了吧？真是拿你没办法呢，这样下去可是会秃头的哦？', // 5
    '人望高處，水向下流（發自你的手機）',
    '滴——学生卡',
    '签到！今天也是防止人类大脑退化实验的志愿者之一。',
    '只要我签到的速度够快，懒惰就追不上我。',
    '嗨~想我了吗？', // 10
    '一天了！生产队的驴都不敢这么歇！',
    '已醒，勿念',
    '别问我心里有没有你，我课表里都是你。',
    '签到成功！如果觉得辛苦，没关系，明天会更辛苦的。',
    '报告！身体已成功搬运出宿舍，灵魂仍在路上。', // 15
    '您的“困兽”已被暂时封印，有效期至下一堂无聊的课。',
    '签到成功！所以…昨晚说要早睡，你做到了吗？',
    '𝑪𝒊𝒂𝒍𝒍𝒐~(∠・ω < )⌒★',
    '哈—啊——这么早就要应付你签到，好困啊……',
    '哦？还知道中午要来签个到？还以为你的脑子跟上午一起被消化掉了呢！', // 20
    '喂喂！这么晚还不睡是在干嘛？想猝死然后让我换个聪明点的主人吗？…快、快去睡觉啊！💢',
    '需要我借你点智商吗？…算了，借了你可能也还不起，略略略~',
    '需要我帮你把“困倦”技能点调低一些吗？…不过你好像天生就是满级呢，噗！',
    '存在先于本质，签到先于学习。——鲁迅（没说过）',
    '是我签到了今天，还是今天签到了我？', // 25
    '您订购的“崭新一天”已到货，请签收',
    '签到有什么用？问得好，但你还是点了。',
    '可…可恶！我想不到新的签到词了！(；´д｀)ゞ…你给出几个点子？',
    '早八人，早八魂，签到完毕继续困，接着奏乐接着舞！',
    '签到成功！今天演得差不多，可以准备谢幕了', // 30
    '今天的你，也是一如既往地充满活力呢！',
    '……嗯呃…啊啊？哦！哦…早上好呀……',
    '哟~今天来得挺早嘛，是不是偷偷想我了？',
    '签到成功！今天也要努力做一个不逃课的乖孩子哦~',
    '喂喂喂，别以为签个到就能证明你来过了，心没来可不行！', //35
    '你该不会是为了看我才签到的吧？…哼，我才不会高兴呢！',
    '签到成功！今天的你，有没有比昨天更聪明一点点呢？…没有就算了罢。',
    '唔…今天不想写签到词，你自己脑补一句好听的行不行？',
    '签到完成！记得喝水，记得吃饭，记得…记得想我！',
    '呼…终于签到了，我还以为你今天要翘课去打 boss 呢。', // 40
    '晚饭吃了吗？没吃的话…我也没办法，我又不会做饭。（摊手）',
    '早安！昨晚梦见我了吗？…没有？那今晚继续梦！',
    '早餐吃了吗？没吃的话，签个到就当精神食粮吧~',
    'Mi Do Sol La Fa~Re Mi Fa~Mi Re Mi♪',
    ' \udb81\udcc4   ？？？', // 45
    '你来了，世界就亮了。（我开的灯）',
    '让我用双手给你比个小鸽子，扑腾着翅膀…快看，飞起来咯~',
    '这么晚还不睡觉？你不睡觉，地球OL怎么刷新呢？',
    '嘘——别说话。好啦，今天的第一分钟已经是我的了。', // 49
  ];

  private static TIME_TO_INDEX: number[][] = [
    [0, 2, 6, 7, 8, 9, 10, 11, 13, 14, 18, 21, 22, 23, 24, 25, 26, 27, 28, 33, 36, 38, 44, 45, 46, 48, 49], // 半夜: 0~4点
    [1, 3, 4, 5, 6, 7, 8, 9, 10, 12, 13, 15, 16, 17, 18, 19, 22, 23, 24, 26, 27, 28, 29, 32, 33, 34, 35, 37, 39, 40, 42, 43, 49], // 早晨: 5~9点
    [0, 5, 6, 7, 8, 9, 10, 12, 13, 14, 16, 17, 18, 20, 22, 23, 24, 25, 27, 28, 31, 34, 35, 37, 39, 40, 44, 45, 47], // 白天: 10~18点
    [0, 6, 7, 8, 9, 10, 11, 12, 13, 14, 18, 22, 23, 24, 25, 27, 28, 30, 31, 36, 38, 41, 44, 45, 46, 47], // 晚上: 19~24点
  ]

  private static millisecondsInADay = 86400000;
  private static defaultTimestamp = '1000000000'; // 用于没有签到记录时的Unix时间戳

  // 主题抽取权重：命中主题时以该概率抽主题签到词，否则走分时段通用池
  private static readonly THEMED_WEIGHT_DAILY: number = 0.35; // 有课日/无课日（高频主题，权重放低）
  private static readonly THEMED_WEIGHT_EXAM: number = 0.7;   // 考试日
  private static readonly THEMED_WEIGHT_RARE: number = 0.85;  // 节日、开学、学期末等低频主题

  // —— 主题签到词（唯一数据源，追加在通用签到词之后）——
  private static readonly THEMED_SECTIONS: ThemedSection[] = CheckInTools.buildThemedSections();

  // 全量签到词 = 通用 + 主题（收藏页按总下标展示与收集）
  static readonly CHECK_IN_CONTENT_LIST: string[] = CheckInTools.buildFullContentList();

  // 各主题在 CHECK_IN_CONTENT_LIST 中的下标池（key 含义见 ThemedSection 注释）
  private static readonly THEME_INDICES: Map<string, number[]> = CheckInTools.buildThemeIndices();

  static getTodayDate(): number { // 保留年、月、日，忽略时、分、秒
    const date = new Date();
    return new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
  }

  static timeSinceLastCheckIn(): number {
    const previousTime = Number(UnifiedPreferences.getSync(LAST_DAY_KEY, CheckInTools.defaultTimestamp));
    const currentTime = CheckInTools.getTodayDate();
    return currentTime - previousTime;
  }

  static getRandomContent(): number {
    const collection = CheckInTools.getCollectionStatus();

    // 命中主题（节日/考试/有课等）时按权重优先抽主题池，未命中或概率落空则走分时段通用池
    const themedKey = CheckInTools.getThemedKeyToday();
    if (themedKey !== null) {
      const themedIndices = CheckInTools.THEME_INDICES.get(themedKey);
      if (themedIndices !== undefined && themedIndices.length > 0
        && Math.random() < CheckInTools.themedWeightOf(themedKey)) {
        return CheckInTools.weightedPick(themedIndices, collection);
      }
    }
    return CheckInTools.weightedPick(CheckInTools.getTimeIndices(), collection);
  }

  static loadCheckInOnStartup(): [number, number, boolean, string] {
    const checkInTotal = Number(UnifiedPreferences.getSync(TOTAL_DAYS_KEY, '0'));
    const timeSinceLastCheckIn = CheckInTools.timeSinceLastCheckIn();
    const checkInConsecutive = timeSinceLastCheckIn <= CheckInTools.millisecondsInADay ? Number(UnifiedPreferences.getSync(CONSECUTIVE_DAYS_KEY, '0')) : 0; // 超过1天未签到就把“连续签到”计数归零
    const checkedInToday = timeSinceLastCheckIn === 0;
    const checkInContent = UnifiedPreferences.getSync(CONTENT_KEY, '') as string;
    return [checkInTotal, checkInConsecutive, checkedInToday, checkInContent];
  }

  static doCheckIn(): [number, number, string] {

    // 签到次数加1，判断是否连续
    const newTotal = Number(UnifiedPreferences.getSync(TOTAL_DAYS_KEY, '0')) + 1;
    let newConsecutive = Number(UnifiedPreferences.getSync(CONSECUTIVE_DAYS_KEY, '0'));
    if (CheckInTools.timeSinceLastCheckIn() === CheckInTools.millisecondsInADay) {
      newConsecutive += 1;
    } else {
      newConsecutive = 1;
    }
    const randomIndex: number = CheckInTools.getRandomContent();
    const randomContent: string = CheckInTools.CHECK_IN_CONTENT_LIST[randomIndex];
    CheckInTools.recordCollection(randomIndex);

    // 写入首选项并落盘
    UnifiedPreferences.putSync(LAST_DAY_KEY, CheckInTools.getTodayDate());
    UnifiedPreferences.putSync(TOTAL_DAYS_KEY, newTotal);
    UnifiedPreferences.putSync(CONSECUTIVE_DAYS_KEY, newConsecutive);
    UnifiedPreferences.putSync(CONTENT_KEY, randomContent);

    return [newTotal, newConsecutive, randomContent];
  }

  static getCollectionStatus(): boolean[] {
    const result: boolean[] = JSON.parse(UnifiedPreferences.getSync('CheckinCollection', '[]'));
    const listLen: number = CheckInTools.CHECK_IN_CONTENT_LIST.length;
    for (let i = 0; i < listLen; i++)
      if (result[i] === undefined)
        result[i] = false;
    return result;
  }

  static getCollectionNumber(): number {
    const rec: boolean[] = CheckInTools.getCollectionStatus();
    let count: number = 0;
    for (let i = 0; i < CheckInTools.CHECK_IN_CONTENT_LIST.length; i++)
      if (rec[i])
        count++;
    return count;
  }

  static recordCollection(rec: number) {
    const origin = CheckInTools.getCollectionStatus();
    origin[rec] = true;
    UnifiedPreferences.putSync('CheckinCollection', JSON.stringify(origin));
  }

  // ==================== 当日状态判断 ====================

  /**
   * 判断当天是否为特殊日期（公历节日、农历节日、开学第一天、学期最后一天）
   * @returns 命中时返回主题名称（如 '国庆节'），未命中返回 null
   */
  static getSpecialDateToday(): string | null {
    const key = CheckInTools.getSpecialKeyToday();
    if (key === null) {
      return null;
    }
    for (const section of CheckInTools.THEMED_SECTIONS) {
      if (section.key === key) {
        return section.name;
      }
    }
    return null;
  }

  /**
   * 判断今天（默认学期）是否有课程
   * @returns 有课程返回 true
   */
  static hasClassToday(): boolean {
    const now = new Date();
    const semester = ScheduleManager.semesters[ScheduleManager.defaultSemester];
    if (!semester) {
      return false;
    }
    if (now.getTime() < semester.beginTime) { // 学期未开始
      return false;
    }
    if (now.getTime() > semester.beginTime + semester.totalWeekNum * millisecondsPerWeek) { // 学期已结束
      return false;
    }
    const currentWeek = Math.ceil((now.getTime() - semester.beginTime) / millisecondsPerWeek);
    return ScheduleManager.getDefaultClassByDay(currentWeek, now.getDay()).length > 0;
  }

  /**
   * 判断今天是否有考试（按考试日期字符串比较，兼容缺失时间戳的旧数据）
   * @returns 有考试返回 true
   */
  static hasExamToday(): boolean {
    const exams = ExamStorage.getExams();
    const todayStr = CheckInTools.getTodayDateString();
    for (const exam of exams) {
      if (exam && exam.date && exam.date.slice(0, 10) === todayStr) {
        return true;
      }
    }
    return false;
  }

  // ==================== 内部：主题判定 ====================

  /**
   * 获取今天命中的主题 key（主题抽取用），优先级：特殊日期 > 考试日 > 有课日/无课日
   */
  private static getThemedKeyToday(): string | null {
    const specialKey = CheckInTools.getSpecialKeyToday();
    if (specialKey !== null) {
      return specialKey;
    }
    if (CheckInTools.hasExamToday()) {
      return 'exam';
    }
    return CheckInTools.hasClassToday() ? 'hasclass' : 'noclass';
  }

  /**
   * 获取今天命中的特殊日期 key，优先级：公历节日 > 农历节日 > 学期派生日期
   */
  private static getSpecialKeyToday(): string | null {
    // 1) 固定公历节日
    const date = new Date();
    const mmdd = `${CheckInTools.pad2(date.getMonth() + 1)}-${CheckInTools.pad2(date.getDate())}`;
    if (CheckInTools.THEME_INDICES.has(mmdd)) {
      return mmdd;
    }
    // 2) 农历节日
    const lunarKey = CheckInTools.getLunarKeyToday();
    if (lunarKey !== null) {
      return lunarKey;
    }
    // 3) 学期派生：开学第一天/学期最后一天
    if (CheckInTools.isTermFirstDayToday()) {
      return 'termstart';
    }
    if (CheckInTools.isTermLastDayToday()) {
      return 'termend';
    }
    return null;
  }

  /**
   * 获取今天命中的农历节日 key。闰月不庆祝节日；除夕取“明天是正月初一”判断，兼容大月小月
   */
  private static getLunarKeyToday(): string | null {
    try {
      const calendar: i18n.Calendar = i18n.getCalendar('zh-Hans', 'chinese');
      const now = new Date();
      calendar.setTime(now);
      const month = calendar.get('month'); // 0 表示正月
      if (calendar.get('is_leap_month') === 0) {
        const key = `l-${month}-${calendar.get('date')}`;
        if (CheckInTools.THEME_INDICES.has(key)) {
          return key;
        }
        // 除夕：今天为腊月（month=11）且明天是正月初一
        calendar.setTime(now.getTime() + CheckInTools.millisecondsInADay);
        if (month === 11 && calendar.get('month') === 0 && calendar.get('date') === 1) {
          return 'l-eve';
        }
      }
    } catch (e) {
      console.error(`CheckIn: getChineseCalendar failed: ${JSON.stringify(e)}`);
    }
    return null;
  }

  /**
   * 今天是否为默认学期的第一天（学期数据无效时不算，如首次使用自动生成的默认学期）
   */
  private static isTermFirstDayToday(): boolean {
    const semester = ScheduleManager.semesters[ScheduleManager.defaultSemester];
    if (!semester || semester.totalWeekNum <= 0) {
      return false;
    }
    const todayStart = CheckInTools.getTodayDate();
    return semester.beginTime >= todayStart && semester.beginTime < todayStart + CheckInTools.millisecondsInADay;
  }

  /**
   * 今天是否为默认学期的最后一天
   */
  private static isTermLastDayToday(): boolean {
    const semester = ScheduleManager.semesters[ScheduleManager.defaultSemester];
    if (!semester || semester.totalWeekNum <= 0) {
      return false;
    }
    const now = new Date().getTime();
    const termEnd = semester.beginTime + semester.totalWeekNum * millisecondsPerWeek;
    return now < termEnd && now > termEnd - CheckInTools.millisecondsInADay;
  }

  private static getTodayDateString(): string {
    const date = new Date();
    return `${date.getFullYear()}-${CheckInTools.pad2(date.getMonth() + 1)}-${CheckInTools.pad2(date.getDate())}`;
  }

  private static pad2(n: number): string {
    return n < 10 ? '0' + n : '' + n;
  }

  // ==================== 内部：签到词抽取 ====================

  private static themedWeightOf(key: string): number {
    if (key === 'hasclass' || key === 'noclass') {
      return CheckInTools.THEMED_WEIGHT_DAILY;
    }
    if (key === 'exam') {
      return CheckInTools.THEMED_WEIGHT_EXAM;
    }
    return CheckInTools.THEMED_WEIGHT_RARE;
  }

  private static getTimeIndices(): number[] {
    const hour = new Date().getHours();
    if (hour < 5) {
      return CheckInTools.TIME_TO_INDEX[0];
    } else if (hour < 10) {
      return CheckInTools.TIME_TO_INDEX[1];
    } else if (hour < 19) {
      return CheckInTools.TIME_TO_INDEX[2];
    } else {
      return CheckInTools.TIME_TO_INDEX[3];
    }
  }

  /**
   * 在下标池内加权随机选择：未收集的权重远大于已收集的
   */
  private static weightedPick(indices: number[], collection: boolean[]): number {
    const WEIGHT_UNCOLLECTED = 5;
    const WEIGHT_COLLECTED = 1;

    const weights: number[] = [];
    let totalWeight = 0;
    for (const idx of indices) {
      const weight = collection[idx] ? WEIGHT_COLLECTED : WEIGHT_UNCOLLECTED;
      weights.push(weight);
      totalWeight += weight;
    }

    let random = Math.random() * totalWeight;
    for (let i = 0; i < indices.length; i++) {
      random -= weights[i];
      if (random <= 0) {
        return indices[i];
      }
    }
    // fallback（理论上不会执行到这里）
    return indices[indices.length - 1];
  }

  // ==================== 内部：签到词数据构建 ====================

  private static buildThemedSections(): ThemedSection[] {
    const sections: ThemedSection[] = [];
    const add = (key: string, name: string, contents: string[]): void => {
      const section: ThemedSection = { key: key, name: name, contents: contents };
      sections.push(section);
    };

    // 固定公历节日
    add('01-01', '元旦', ['元旦快乐！新年的第一句签到词被我抢到了，耶~新的一年也请多指教哦！']);
    add('02-14', '情人节', ['今、今天是情人节没错…但签到和情人节才没有什么关系呢！…巧克力什么的，随便吃一点啦。(脸红)']);
    add('03-07', '女生节', ['女生节快乐！…说吧，想要什么礼物？本系统的库存只有签到词哦。']);
    add('03-08', '妇女节', ['妇女节快乐！说起来，本系统也算个女孩子吧？…礼物什么的，随、随便准备一下就行啦。']);
    add('04-01', '愚人节', ['呐，其实我早就想说了——我喜欢你！…骗你的！愚人节快乐，噗，你的表情太精彩了！']);
    add('05-01', '劳动节', ['劳动节快乐！虽然你今天最大的劳动量，大概就是点了一下签到。']);
    add('05-04', '青年节', ['青年节快乐！风华正茂的你，今天也请继续闪闪发光哦~']);
    add('05-20', '520', ['今天是5月20日…我、我才没有什么想说的呢！系统只是提醒我，今天很适合签到而已！(脸红)']);
    add('06-01', '儿童节', ['六一快乐！虽然你早就不是小孩了…但在家面前，永远可以撒娇哦？']);
    add('09-10', '教师节', ['教师节快乐！记得跟老师们说声谢谢…别只顾着上课摸鱼啊！']);
    add('09-20', '校庆', ['校庆快乐！今天也是这所校园的一员，稍微骄傲一下吧！']);
    add('10-01', '国庆节', ['国庆节快乐！假期计划做好了吗？…让我猜猜，又是“躺满七天”是吧。']);
    add('10-24', '程序员节', ['1024，程序员节快乐！愿你写的代码，一次就能编译通过~（虽然很难啦，噗）']);
    add('10-31', '万圣夜', ['不给糖就捣乱！…骗你的，糖已经被我吃完了，给你一句签到词吧：Trick or Treat~']);
    add('11-11', '双十一', ['双十一快乐！购物车可以清空，但今天签到的奖励，可是清不掉的哦~']);
    add('12-24', '平安夜', ['平安夜快乐！苹果就不送了，送你一句话：今晚要早点睡哦，我看着呢。']);
    add('12-25', '圣诞节', ['圣诞节快乐！礼物？…你的签到记录就是我最好的礼物啦。什么，还想要别的？哼，贪心！']);
    add('12-31', '跨年夜', ['今年的最后一天啦。谢谢你陪我签到…明年，也请多指教哦！']);

    // 农历节日（key 中农历月从 0 计，0 表示正月）
    add('l-0-1', '春节', ['新春快乐！…压岁钱我就不收了，收你一句签到词吧：今年也要元气满满哦！']);
    add('l-0-15', '元宵节', ['元宵节快乐！记得吃汤圆…黑芝麻馅的和花生馅的，你站哪边？']);
    add('l-1-2', '龙抬头', ['二月二，龙抬头！…剃个头讨个好彩头，然后精神抖擞地去签到吧！']);
    add('l-4-5', '端午节', ['端午安康！甜粽咸粽之争又开始了……别争了，先签到，签到的是中立的。']);
    add('l-6-7', '七夕', ['七夕快乐…单、身狗也要开心地签到哦！毕竟，你还有我呢。(小声)']);
    add('l-7-15', '中秋节', ['中秋快乐！今晚的月亮很圆，记得抬头看看…月饼的话，五仁我也不拒绝哦。']);
    add('l-8-9', '重阳节', ['重阳节快乐！记得给家里打个电话…我不吃醋，真的。(小声)']);
    add('l-11-8', '腊八节', ['腊八快乐！过了腊八就是年…作业写完了吗？没写完还想过年？(笑)']);
    add('l-eve', '除夕', ['除夕快乐！年夜饭记得多吃点…今晚守岁的时候，也可以顺手把明天的签到留给我哦。']);

    // 学期派生与每日主题
    add('termstart', '开学第一天', [
      '新学期第一天！课表已刷新，“变成好学生”的机会又来了，这次要抓住哦？',
      '开学第一天就来签到，态度不错嘛。新学期请多指教…还有，早八是不会心软的。',
    ]);
    add('termend', '学期最后一天', [
      '今天是本学期最后一天！这一学期辛苦啦…假期再会，别把签到忘掉了哦。',
      '学期最后一天快乐！…什、什么嘛，不用说得那么感人的啦！反正下学期还会再见。',
    ]);
    add('exam', '考试日', [
      '今天有考试？！喂喂，别盯着签到词看了，快去复习啊！(╬ Ò ω Ó)',
      '考试日限定护身符已发放：考的都会，蒙的全对！…快去考场，迟到了可不负责！',
      '深呼吸。你已经刷了那么多题，今天只是把它们展示出来而已。去吧，我在这里等你凯旋！',
      '都考试日了还来签到？…真拿你没办法，就当是叠个运气 buff 吧。冲！',
      '考完就解放了！所以在那之前，本系统批准你暂时不用想我。……才怪，给我想着一点！',
    ]);
    add('hasclass', '有课日', [
      '今天课表满满的呢…没关系，你每节课我都陪着哦。',
      '再坚持一下，上完这节就解放了！……的下一节。(笑)',
      '有课的日子也要照顾好自己：上课前喝水，下课后伸个懒腰，好不好？',
      '今天也有课吗？路上慢点走…摔着了的话，我、我才不会背你去教室呢！',
    ]);
    add('noclass', '无课日', [
      '今天没课？！羡慕…啊不，我是说：也别整天躺着，出去走走啦！',
      '无课日的自由都是偷来的，别让作业发现哦。……喂，作业写完了吗？！',
      '课表空空的一天，连时间都变甜了呢。…才、才不是想约你出去玩呢！',
      '今天没课还起这么早来签到？…哼，值得表扬！(勉强)',
    ]);
    return sections;
  }

  private static buildFullContentList(): string[] {
    const all: string[] = CheckInTools.BASE_CONTENT_LIST.slice();
    for (const section of CheckInTools.THEMED_SECTIONS) {
      for (const content of section.contents) {
        all.push(content);
      }
    }
    return all;
  }

  private static buildThemeIndices(): Map<string, number[]> {
    const result: Map<string, number[]> = new Map<string, number[]>();
    let offset: number = CheckInTools.BASE_CONTENT_LIST.length;
    for (const section of CheckInTools.THEMED_SECTIONS) {
      const indices: number[] = [];
      for (let i = 0; i < section.contents.length; i++) {
        indices.push(offset + i);
      }
      result.set(section.key, indices);
      offset += section.contents.length;
    }
    return result;
  }
}
