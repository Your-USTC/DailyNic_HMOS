
/**
 * --- 功能页链接表 ---
 */

export interface LinkAddress {
  url: string | Resource;
  subtitle?: string;
  notUrl?: boolean;
}

export interface MultiLink {
  title: ResourceStr;
  url: LinkAddress[];
  icon: ResourceStr;
}

export interface SimpleLink {
  title: ResourceStr;
  url: string | Resource;
}

export interface LinkSet {
  title: ResourceStr;
  set: MultiLink[];
}

export const LINK: LinkSet[] = [
  // 课程学习
  { title: '\udb82\udcbf 课程学习', set: [
    { title: $r('app.string.JiaoWuXiTong'), url: [{ url: 'https://jw.ustc.edu.cn' }], icon: $r('app.media.JiaoWuXiTong') },
    { title: $r('app.string.KeChengBiao'), url: [{ url: 'https://jw.ustc.edu.cn/for-std/course-table' }], icon: $r('app.media.KeChengBiao') },
    { title: $r('app.string.KaoShiXinXi'), url: [{ url: 'https://jw.ustc.edu.cn/for-std/exam-arrange' }], icon: $r('app.media.KaoShiXinXi') },
    { title: $r('app.string.NiDeChengJi'), url: [{ url: 'https://jw.ustc.edu.cn/for-std/grade/sheet' }], icon: $r('app.media.WoDeChengJi') },
    { title: $r('app.string.bbJiaoXuePingTai'), url: [{ url: 'https://www.bb.ustc.edu.cn' }], icon: $r('app.media.bbJiaoXuePingTai') },
    { title: $r('app.string.HanHaiJiaoXueWang'), url: [{ url: 'http://course.ustc.edu.cn/portal' }], icon: $r('app.media.HanHaiJiaoXueWang') },
    { title: $r('app.string.GongGongChaXun'), url: [{ url: 'https://catalog.ustc.edu.cn/query/lesson' }], icon: $r('app.media.GongGongChaXun') },
    { title: $r('app.string.TuShuGuan'), url: [{ url: 'https://lib.ustc.edu.cn' }], icon: $r('app.media.TuShuGuan') },
    { title: $r('app.string.XueXiKongJian'), icon: $r('app.media.XueXiKongJian'), url: [
      { url: 'https://ic.lib.ustc.edu.cn/mobile.html#/ic/homePage', subtitle: '西图研讨室' },
      { url: 'https://roombooking.cmet.ustc.edu.cn/artscenter/booking/#/croom', subtitle: '中区艺术教学中心' },
      { url: 'https://ipb.ustc.edu.cn/main.htm', subtitle: '中区创新实践基地' },
      { url: 'https://hs.lib.ustc.edu.cn/appointment/mobAppointment#/appointment', subtitle: '高新区研讨室' },
      { url: 'https://roombooking.cmet.ustc.edu.cn/protal/wechat/index.html', subtitle: '外语教学中心预约' },
      { url: 'https://roombooking.cmet.ustc.edu.cn/#/sroom', subtitle: '中区青年之家' }]},
    { title: $r('app.string.DaWuShiYan'), icon: $r('app.media.DaWuShiYanYuYue'), url: [
      { url: 'https://pems.ustc.edu.cn', subtitle: '大物实验预约系统' },
      { url: 'https://phytools.xef2.top', subtitle: 'PhyTools by XeF2' },
      { url: 'https://dawu.feixu.site', subtitle: '大雾实验工具 by 飞旭' },
      { url: 'https://dwsy.wsw.wiki', subtitle: '大物实验工具站 by 五水' },
      { url: 'https://temp-dwsy.wsw.wiki', subtitle: '数据分析辅助工具 by 五水' }]},
    { title: $r('app.string.KeChengZiLiao'), icon: $r('app.media.KeChengZiLiao'), url: [
      { url: 'https://share.feixu.site', subtitle: '我的科大' },
      { url: 'https://share.ustcer.top', subtitle: 'Share USTC' },
      { url: 'https://ustc-resource.github.io/USTC-Course', subtitle: 'USTC-Course' },
      { url: 'https://ustcmathexam.github.io', subtitle: '数学' },
      { url: 'https://ustcphyexam.github.io', subtitle: '物理' },
      { url: 'https://github.com/ustcwpz/USTC-CS-Courses-Resource', subtitle: '计算机' }]},
    { title: $r('app.string.PingKeSheQu'), url: [{ url: 'https://icourse.club' }], icon: $r('app.media.PingKeSheQu') },
    { title: $r('app.string.ZhuJiaoXiTong'), url: [{ url: 'https://tam.cmet.ustc.edu.cn' }], icon: $r('app.media.ZhuJiaoXiTong') },
    { title: $r('app.string.WoKeXueShe'), url: [{ url: 'https://ot.ustc.edu.cn' }], icon: $r('app.media.WoKeXueShe') },
    { title: $r('app.string.KeChengPingTai'), icon: $r('app.media.KeChengPingTai'), url: [
      { url: 'https://onlineweb.zhihuishu.com', subtitle: '智慧树' },
      { url: 'https://i.chaoxing.com', subtitle: '学习通' },
      { url: 'https://www.icourse163.org/university/USTC#/c', subtitle: '慕课' },
      { url: 'https://wsdx.ustc.edu.cn', subtitle: '网上党校' }]},
    { title: $r('app.string.JiKaoZiCe'), icon: $r('app.media.JiKaoZiCe'), url: [
      { url: 'MockPracticeList', subtitle: '本地答题', notUrl: true },
      { url: 'https://ti.u5tc.cn/', subtitle: 'vitx 答题' },
      { url: 'https://quiz-stack.enthusjast.cc/', subtitle: 'Quiz Stack' }]},
    { title: $r('app.string.JiSuanGongJu'), icon: $r('app.media.JiSuanGongJu') , url: [
      { url: 'https://wolframalpha.com', subtitle: 'Wolfram Alpha' },
      { url: 'https://www.desmos.com/?lang=zh-CN', subtitle: 'Desmos' },
      { url: 'https://www.geogebra.org/calculator', subtitle: 'GeoGebra 计算器套件'}]}
  ]},
  // 网络资源
  { title: '\udb81\uddf1 网络资源', set: [
    { title: $r('app.string.KeDaYouXiang'), url: [{ url: 'http://mail.ustc.edu.cn' }], icon: $r('app.media.KeDaYouXiang') },
    { title: $r('app.string.KeDaYunPan'), url: [{ url: 'https://pan.ustc.edu.cn/login?redirect=/home/index' }], icon: $r('app.media.KeDaYunPan') },
    { title: $r('app.string.KeDaVPN'), url: [{ url: 'https://wvpn.ustc.edu.cn' }], icon: $r('app.media.KeDaVPN') },
    { title: $r('app.string.WenDangXieZuo'), url: [{ url: 'https://latex.ustc.edu.cn' }], icon: $r('app.media.WenDangXieZuo') },
    { title: $r('app.string.KeDaOJ'), url: [{ url: 'https://oj.ustc.edu.cn' }], icon: $r('app.media.KeDaOJ') },
    { title: $r('app.string.JiYuanKeYanPingTai'), url: [{ url: 'https://cscourse.ustc.edu.cn' }], icon: $r('app.media.JiYuanKeYanPingTai') },
    { title: $r('app.string.Gitlab'), icon: $r('app.media.GitLab'), url: [
      { url: 'https://git.ustc.edu.cn', subtitle: '科大官方 GitLab' },
      { url: 'https://git.lug.ustc.edu.cn', subtitle: 'Linux 用户协会 GitLab' }] },
    { title: $r('app.string.Vlab'), url: [{ url: 'https://vlab.ustc.edu.cn' }], icon: $r('app.media.VlabShiYanZhongXin') },
    { title: $r('app.string.CiYuanJiHua'), url: [{ url: 'https://llm.ustc.edu.cn/api/auth/oauth/login' }], icon: $r('app.media.CiYuanJiHua') },
    { title: $r('app.string.107'), url: [{ url: 'https://107.ustc.edu.cn' }], icon: $r('app.media.107') },
    { title: $r('app.string.LUG'), url: [{ url: 'https://lug.ustc.edu.cn' }], icon: $r('app.media.LUG') },
    { title: $r('app.string.WangLuoTong'), url: [{ url: 'https://zczx.ustc.edu.cn' }], icon: $r('app.media.WangLuoTong') },
    { title: $r('app.string.YiKaTong'), url: [{ url: 'https://ecard.ustc.edu.cn' }], icon: $r('app.media.YiKaTong') },
    { title: $r('app.string.ZhengBanRuanJian'), url: [{ url: 'https://software.ustc.edu.cn' }], icon: $r('app.media.ZhengBanRuanJian') },
    { title: $r('app.string.KaiYuanJingXiang'), url: [{ url: 'https://mirrors.ustc.edu.cn' }], icon: $r('app.media.KaiYuanJingXiang') }
  ]},
  // 办事服务
  { title: '\udb81\ude60 办事服务', set: [
    { title: $r('app.string.JiaoShiChaXun'), url: [{ url: $rawfile('BuildingQuery.html') }], icon: $r('app.media.JiaoShiChaXun') },
    { title: $r('app.string.ZhiHuiMenHu'), url: [{ url: 'http://i.ustc.edu.cn' }], icon: $r('app.media.ZhiHuiMenHu') },
    { title: $r('app.string.QingChunKeDa'), icon: $r('app.media.QingChunKeDa'), url: [
      { url: 'https://id.ustc.edu.cn/cas/login?service=https:%2F%2Fyoung.ustc.edu.cn%2Flogin%2Fustc-h5-product%2Fpages%2Flogtransit%2Flogtransit', subtitle: '青春科大'},
      { url: 'https://young.ustc.edu.cn/login', subtitle: '青春科大(PC)' }]},
    { title: $r('app.string.JiaoWuChu'), url: [{ url: 'https://teach.ustc.edu.cn' }], icon: $r('app.media.JiaoWuChu') },
    { title: $r('app.string.LianXiFangShi'), icon: $r('app.media.LianXiFangShi'), url: [
      { url: 'https://www.teach.ustc.edu.cn/service/svc-student/4427.html', subtitle: '本科生教学秘书' },
      { url: 'https://gradschool.ustc.edu.cn/column/161', subtitle: '研究生教学秘书' },
      { url: 'https://employment.ustc.edu.cn/cn/recruitment/uploadfile/P0327/635658093947187004.pdf', subtitle: '学校常用联系方式' }]},
    { title: $r('app.string.QinYouRuXiao'), url: [{ url: 'https://passport.ustc.edu.cn/login?service=http%3A%2F%2Fbwcqyrx.ustc.edu.cn%2Fweixin%2Fvalidate' }], icon: $r('app.media.QinYouRuXiao') },
    { title: $r('app.string.GuoJiJiaoLiu'), url: [{ url: 'https://vista.ustc.edu.cn' }], icon: $r('app.media.GuoJiJiaoLiu') },
    { title: $r('app.string.LiFanXiaoDengJi'), url: [{ url: 'https://lfxdj.ustc.edu.cn' }], icon: $r('app.media.LiFanXiaoDengJi') },
    { title: $r('app.string.XueGongYiTiHua'), url: [{ url: 'https://xgyth.ustc.edu.cn' }], icon: $r('app.media.XueGongYiTiHua') },
    { title: $r('app.string.YuanXiZhuanYe'), url: [{ url: 'https://www.teach.ustc.edu.cn/education/239.html' }], icon: $r('app.media.YuanXiZhuanYe') },
  ]},
  // 校园生活
  { title: '\udb82\udc0d 校园生活', set: [
    { title: '体测系统', icon: $r('app.media.TiCeXiTong'), url: [
      { url: 'http://id.ustc.edu.cn/cas/oauth2.0/authorize?response_type=code&client_id=ZHTZCSXT&redirect_uri=https%3A%2F%2Ftc.ustc.edu.cn%2Fsunshine%2Flogin%2Fustc%2FloginRedirect', subtitle: '阳光跑' },
      { url: 'http://id.ustc.edu.cn/cas/oauth2.0/authorize?response_type=code&client_id=ZHTZCSXT&redirect_uri=https%3A%2F%2Ftc.ustc.edu.cn%2Ffitness%2Flogin%2Fustc%2FloginRedirect', subtitle: '体测' }
    ]},
    { title: $r('app.string.XiaoYuanBanChe'), url: [{ url: 'https://weixine.ustc.edu.cn/ustcqy/mobile/busTimetable_gov' }], icon: $r('app.media.XiaoYuanBanChe') },
    { title: $r('app.string.QunLiaoHuiZong'), icon: $r('app.media.QunLiaoHuiZong'), url: [
      { url: 'https://docs.qq.com/sheet/DZHZ0b2lVZmFMenFw', subtitle: '科大各类群汇总'},
      { url: 'https://ustcgroup.pages.dev/', subtitle: 'USTC 群聊信息汇总'}]},
    { title: $r('app.string.YingJuGouPiao'), url: [{ url: "https://ghticket.ustc.edu.cn" }], icon: $r('app.media.YingJuGouPiao') },
    { title: $r('app.string.BaoXiuDaTing'), url: [{ url: 'https://xsfw.ustc.edu.cn' }], icon: $r('app.media.BaoXiuDaTing') },
    { title: $r('app.string.XiaoYiYuan'), url: [{ url: 'https://hospital.ustc.edu.cn/main.htm' }], icon: $r('app.media.XiaoYiYuan') },
    { title: $r('app.string.HuaZhuShangLv'), url: [{ url: 'https://i.ustc.edu.cn/page/mobile/huazhu' }], icon: $r('app.media.HuaZhuShangLv') },
    { title: $r('app.string.XiaoYuanDiTu'), icon: $r('app.media.XiaoYuanDiTu'), url: [
      { url: 'https://map.ustc.edu.cn/m', subtitle: '二维地图' },
      { url: 'https://vr.shouxi360.com/c/vyS6HSJjeej.html', subtitle: '全景地图' }]},
    { title: $r('app.string.XueShengYiBao'), url: [{ url: 'https://xsybxt.ustc.edu.cn' }], icon: $r('app.media.XueShengYiBao') },
    { title: $r('app.string.Nan7JiShi'), url: [{ url: 'https://nan7market.com' }], icon: $r('app.media.Nan7JiShi') },
    { title: $r('app.string.Nan7LunTan'), url: [{ url: 'https://ustcforum.com' }], icon: $r('app.media.Nan7LunTan') },
    { title: $r('app.string.YingXinWang'), url: [{ url: 'http://welcome.ustc.edu.cn' }], icon: $r('app.media.YingXinWang') }
  ]}
]