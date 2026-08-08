import UnifiedPreferences from './UnifyPreference';
import * as FunctionOrder from './FunctionOrder';
import * as ScheduleStorage from './ScheduleStorage';
import { classAttribute, semesterAttribute } from '../constants/ScheduleSources';
import { LINK } from '../constants/Links';
import { currentDataVersion } from '../constants/BasicConstants';

const DATA_VERSION_KEY = 'DataVersion';

/**
 * 读取已持久化的数据版本号；从未迁移过（首次安装）时返回 ''。
 */
function getStoredVersion(): string {
  return UnifiedPreferences.getSync(DATA_VERSION_KEY, '');
}

function setStoredVersion(version: string): void {
  UnifiedPreferences.putSync(DATA_VERSION_KEY, version);
}

/**
 * 迁移步骤：2.1.1 -> 2.2.0
 * 将旧版保存在 UnifyPreference 中的「最近使用」点击数据与 maxRecord，
 * 迁移到独立的 functionOrder.json 文件，随后清理 UnifyPreference 中对应的历史键。
 * 课表也迁移到独立 json 文件。
 */
function migrateV211ToV220(): void {
  const legacyData: Record<string, number> = {};
  for (let gridIndex = 0; gridIndex < LINK.length; gridIndex++) {
    const setLen: number = LINK[gridIndex].set.length;
    for (let index = 0; index < setLen; index++) {
      const key = `${gridIndex}.${index}`;
      if (UnifiedPreferences.hasSync(key)) {
        legacyData[key] = UnifiedPreferences.getNumberSync(key, 0);
      }
    }
  }
  if (Object.keys(legacyData).length > 0) {
    FunctionOrder.importLegacyData(legacyData, UnifiedPreferences.getNumberSync('maxRecord', 8));
    for (const key of Object.keys(legacyData)) {
      UnifiedPreferences.deleteSync(key);
    }
  }
  if (UnifiedPreferences.hasSync('maxRecord')) {
    UnifiedPreferences.deleteSync('maxRecord');
  }

  // 课表（semesters / SemesterDataAt* / DefaultSemester）迁入 scheduleData.json
  if (UnifiedPreferences.hasSync('SemestersData')) {
    const attributes: semesterAttribute[] = JSON.parse(UnifiedPreferences.getSync('SemestersData', '[]')) as semesterAttribute[];
    const coursesByCreateTime: Record<string, classAttribute[]> = {};
    for (const attribute of attributes) {
      const key = 'SemesterDataAt' + String(attribute.createTime);
      if (UnifiedPreferences.hasSync(key)) {
        try {
          coursesByCreateTime[String(attribute.createTime)] = JSON.parse(UnifiedPreferences.getSync(key, '[]')) as classAttribute[];
        } catch (e) {
          console.error('MigrationManager: failed to parse legacy schedule:', JSON.stringify(e));
        }
        UnifiedPreferences.deleteSync(key);
      }
    }
    ScheduleStorage.importLegacyData(UnifiedPreferences.getNumberSync('DefaultSemester', 0), attributes, coursesByCreateTime);
    UnifiedPreferences.deleteSync('SemestersData');
    UnifiedPreferences.deleteSync('DefaultSemester');
  }
}

/**
 * 统一的版本迁移入口。应在用户数据初始化完成、功能调用之前执行一次。
 * 根据已持久化的数据版本号，按序执行所有未执行的迁移步骤，并更新版本号。
 */
export function migrate(): void {
  try {
    const storedVersion: string = getStoredVersion();
    if (storedVersion !== currentDataVersion) {
      migrateV211ToV220();
      setStoredVersion(currentDataVersion);
    }
  } catch (e) {
    console.error('MigrationManager: migration failed:', JSON.stringify(e));
  }
}