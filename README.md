
<div align="center">

# <image src="AppScope/resources/base/media/icon_round.png" height="28" width="28"/> 妮可之记 <br> <font size="4">for HarmonyOS NEXT</font>

<image src="resources/introduction.png" width="100%"/>

[![Stars](https://img.shields.io/github/stars/Your-USTC/DailyNic_HMOS)](https://github.com/Your-USTC/DailyNic_HMOS)
&nbsp;
[![Forks](https://img.shields.io/github/forks/Your-USTC/DailyNic_HMOS)](https://github.com/Your-USTC/DailyNic_HMOS)

[![Release](https://img.shields.io/github/v/release/Your-USTC/DailyNic_HMOS)](https://github.com/Your-USTC/DailyNic_HMOS/releases/latest)
&nbsp;
[![Downloads](https://img.shields.io/github/downloads/Your-USTC/DailyNic_HMOS/total)](https://github.com/Your-USTC/DailyNic_HMOS/releases/latest)

![Repo size](https://img.shields.io/github/repo-size/Your-USTC/DailyNic_HMOS)
&nbsp;
![ArkTS](https://img.shields.io/badge/ArkTS-blue)

### 中国科大一站式导航 · 开启你的智慧校园

###### [App 主页](https://dailynic.feixu.site/) | [华为应用商店 AppGallery](https://appgallery.huawei.com/app/detail?id=com.nic.dailynic) | [用户协议 & 隐私政策](https://cdn.jsdelivr.net/gh/Your-USTC/DailyNic_HMOS@main/entry/src/main/resources/rawfile/TermsOfUse.html)

</div>

> [!NOTE]
> 此为最终版本，旧版内容请移步`legacy`分支

## 功能介绍

### 课程与考试信息管理

- [x] 从教务系统自动提取课表/考试信息，并导入到本地
- [x] 在首页显示今日与明日课程、考试倒计时
- [x] 点击课程/考试以查看显示详情
- [x] 手动添加、修改、删除、导入和导出课程/考试
- [x] 将课程/考试导入系统日历，设置提醒时间，或清除本 App 创建的所有日程
- [x] 在多个学期的课表之间切换
- [x] 针对可能的错误和崩溃启用恢复模式

### 校园常用功能链接

- [x] 在功能页分类显示链接，并用内置浏览器打开
- [x] 显示“最常访问”，并可清空或定制显示数量
- [x] 内置浏览器支持切换 UA、前进/后退、上传/下载文件、释放缓存、在系统浏览器中打开

### 用户界面 (UI) 和其它

- [x] 适配鸿蒙多端设备（手机/平板/PC）
- [x] 适配浅色/深色模式
- [x] 可高度自定义背景图片，支持设置不同的主题色以与背景图相适应
- [x] 网页可强制以深色模式显示
- [x] 定制首页功能
- [x] “你的课表”和“考试信息”可添加至桌面卡片

## 软件截图

### Mate 70 Pro+
<image src="resources/phone_1.png" width="160"/><image src="resources/phone_2.png" width="160"/><image src="resources/phone_3.png" width="160"/><image src="resources/phone_4.png" width="160"/>

### MatePad Air 12 2025
<image src="resources/pad.png" width="480"/>

## 系统要求
`HarmonyOS NEXT 6.1.0`及以上版本

## 开发指南

### 环境构建

1. 注册一个华为[开发者账号](https://developer.huawei.com/consumer/cn/)，如果仅运行在自己的设备上则无需实名认证
2. 下载 [DevEco Studio 6.0.0](https://developer.huawei.com/consumer/cn/deveco-studio/)
3. Fork 本仓库并将 Fork 后你自己的仓库下载到本地
4. 将 `build-profile.json5.bak` 重命名为 `build-profile.json5` 并配置签名
5. 将 `entry/src/main/ets/utils/Encryption.ets.bak` 重命名为 `Encryption.ets` 并配置 RSA 密钥
6. （可选）修改相应 链接/图标 和 课表/考试 提取函数
7. 在手机/平板的系统设置中，打开“xxx的xxx”（例如：user的Mate 70 Pro+），连续点击“软件版本”7次，启用“开发者选项”（需要输入密码并重启）
8. 转到 设置→系统→开发者选项→打开“USB调试”
9. 在 DevEco Studio 中打开项目，将手机/平板连接到电脑并信任你的电脑，然后点击标题栏中的绿色三角形，即可安装到你的手机/平板上。需要登录华为账号并在右上角<image src="resources/signature.png" style="vertical-align: top; height: 1.2em;"/>处签名

### 项目结构

<details>
<summary>查看</summary>

```
AppScope/                                   // 应用信息、全局资源

entry/src/main/
│
├── module.json5                            // 主程序配置信息
│
├── resources/                              // 主程序资源目录
│   └── base/profile/                       // 页面、卡片、快捷方式配置
│
└── ets/                                    // 源代码目录
    │
    │   // 应用程序
    │
    ├── entryability/
    │   └── EntryAbility.ets                // 应用程序入口点
    │
    ├── pages/
    │   ├── Index.ets                       // 应用程序主体框架
    │   ├── Webview.ets                     // 浏览器页面
    │   ├── Schedule.ets                    // 本地课表页面
    │   ├── ExamDetail.ets                  // 本地考试信息页面
    │   ├── GetSchedule.ets                 // 同步在线课表、考试页面
    │   ├── Help.ets                        // 帮助页面
    │   ├── About.ets                       // 关于页面
    │   └── FaultOccurred.ets               // 恢复模式页面
    │
    ├── constants/
    │   ├── ScheduleSources.ets             // 课表数据结构
    │   ├── GridListDataSources.ets         // 功能页按钮表
    │   ├── GridListIcons.ets               // 功能页图标表
    │   ├── Links.ets                       // 功能页链接表
    │   ├── ListDataConstants.ets           // 功能页分区标题表
    │   ├── SettingsSources.ets             // 设置页选项表
    │   └── UserAgent.ets                   // Webview UA 参数
    │
    ├── utils/
    │   ├── CheckIn.ets                     // 签到功能
    │   ├── ExamManager.ets                 // 考试信息管理类
    │   ├── FunctionOrder.ets               // 最常访问功能
    │   ├── TimeTable.ets                   // 课表管理类、在线课表获取脚本
    │   ├── tools.ets                       // 公共工具区
    │   ├── UnifyPreference.ets             // 全局共享首选项读写功能
    │   ├── WriteCalendar.ets               // 系统日历读写功能
    │   │
    │   ├── jsencrypt/                      // 加密功能
    │   └── Encryption.ets                  // 加密功能接口
    │
    ├── view/
    │   ├── BgImageManager.ets              // 背景图片控制
    │   ├── BgImageDialog.ets               // 背景图片弹窗
    │   ├── GridComponent.ets               // 功能组件
    │   ├── SettingsComponent.ets           // 设置项组件
    │   └── PasswordDialog.ets              // 账号密码弹窗
    │
    │   // 服务卡片
    │
    ├── entryformability/
    │   └── EntryFormAbility.ets            // 卡片生命周期接口
    │
    └── class_schedule_daily/
        ├── pages/
        │   └── Class_schedule_dailyCard.ets// 卡片主程序
        ├── view/
        │   └── CardListComponent.ets       // 卡片框架
        └── viewmodel/
            └── CardListParameter.ets       // 卡片构造函数
```

</details>

## 开源许可

[<image src="https://gnu.ac.cn/graphics/gplv3-or-later.svg" height="18"/> **GNU General Public License v3.0 (GPLv3)**](LICENSE)

DailyNic  Copyright © 2026  YourUSTC Developer Team
