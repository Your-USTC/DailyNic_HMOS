
import { Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import ScheduleManager from '../utils/Classes/ScheduleManager';
import * as ScheduleSources from '../constants/ScheduleSources';
import examManager, { examAttribute } from '../utils/ExamManager';
import UnifiedPreferences, { millisecondsPerWeek } from '../utils/UnifyPreference';
import { i18n } from '@kit.LocalizationKit';

const TAG: string = 'EntryFormAbility';
const DOMAIN_NUMBER: number = 0xFF00;

class FormDataClass {
  todayCourse: ScheduleSources.classAttribute[] = [];
  tomorrowCourse: ScheduleSources.classAttribute[] = [];
  title: ResourceStr = '';
  count: number = 0;
  examInfo: examAttribute[] = [];
  lastRefresh: string = '';
  currentTime: number = 0;
  constructor(refreshType: number) {
    const currentTime = new Date();
    this.currentTime = currentTime.getTime();
    if (refreshType === 0) { // 0 → 刷新课表
      ScheduleManager.init();
      this.title = $r("app.string.schedule_card_title");
      const termStartTime: number = ScheduleManager.semesters[ScheduleManager.defaultSemester].beginTime;

      let currentWeek: number = 0;
      if (this.currentTime < termStartTime) {
        currentWeek = 1;
        this.todayCourse = this.tomorrowCourse = [];
      } else if (this.currentTime > termStartTime + ScheduleManager.semesters[ScheduleManager.defaultSemester].totalWeekNum * millisecondsPerWeek) {
        currentWeek = 1;
        this.todayCourse = this.tomorrowCourse =  [];
      } else {
        currentWeek = Math.ceil((this.currentTime - termStartTime) / millisecondsPerWeek);

        // const todayStart: number = new Date(currentTime).setHours(0, 0, 0, 0);
        this.todayCourse = ScheduleManager.getDefaultClassByDay(currentWeek, currentTime.getDay())
        // .filter(item => ScheduleSources.commonClassStamp[item.timeSpan[item.timeSpan.length - 1]][1] + todayStart > this.currentTime)
          .sort((a, b) => a.timeSpan[0] - b.timeSpan[0]);

        this.tomorrowCourse = ScheduleManager.getDefaultClassByDay(currentWeek + (currentTime.getDay() === 6 ? 1 : 0), (currentTime.getDay() + 1) % 7)
          .sort((a, b) => a.timeSpan[0] - b.timeSpan[0]);
      }

      //this.cardListParameter.itemCount = this.todayCourse.length;
      this.count = this.todayCourse.length;
    } else if (refreshType === 1) { // 1 → 刷新考试
      this.title = $r("app.string.exam_detail");
      examManager.readStoredExam();
      this.examInfo = examManager.allExamInfo.filter(item => this.currentTime <= item.endTimeStamp);
      this.count = this.examInfo.length;
    }
    this.lastRefresh = '上次刷新: ' + currentTime.toLocaleString('zh-cn', { month: 'short', day: 'numeric', hour: '2-digit', minute: 'numeric', hourCycle: i18n.System.is24HourClock() ? 'h23' : 'h12' });
  }
}

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want) {
    // Called to return a FormBindingData object.
    UnifiedPreferences.init(this.context);
    // console.log(JSON.stringify(want.parameters))

    if (want.parameters![formInfo.FormParam.NAME_KEY].toString() === 'class_schedule_daily') {
      UnifiedPreferences.putSync('CardType_id' + want.parameters![formInfo.FormParam.IDENTITY_KEY], 0);
      return formBindingData.createFormBindingData(new FormDataClass(0));
    } else {
      UnifiedPreferences.putSync('CardType_id' + want.parameters![formInfo.FormParam.IDENTITY_KEY], 1);
      return formBindingData.createFormBindingData(new FormDataClass(1));
    }
  }

  onCastToNormalForm(formId: string) {
    // Called when the form provider is notified that a temporary form is successfully
    // converted to a normal form.
  }

  onUpdateForm(formId: string/*, param: Record<string, object>*/) {
    /* param 没用。参数示例如右：{"form_connect_id":224930369,"moduleName":"","ohos.extra.param.key.form_user_id":100}
     测试时的formId为1489478270
    */
    // Called to notify the form provider to update a specified form.
    UnifiedPreferences.init(this.context);
    const formType: number = UnifiedPreferences.getNumberSync('CardType_id' + formId, -1);

    if (formType !== -1) {
      let formData = new FormDataClass(formType);

      formProvider.updateForm(formId, formBindingData.createFormBindingData(formData)).then(() => {
        hilog.info(DOMAIN_NUMBER, TAG, 'FormAbility updateForm success.');
        console.info('FormAbility updateForm success');
      }).catch((error: Error) => {
        hilog.error(DOMAIN_NUMBER, TAG, `Operation updateForm failed. Cause: ${JSON.stringify(error)}`);
      });
    }
  }

  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `FormAbility onFormEvent, formId = ${formId}, message: ${JSON.stringify(message)}`);

    UnifiedPreferences.init(this.context);
    const eventSource: string = JSON.parse(message).msgTest;
    let formData = new FormDataClass(eventSource === 'schedule' ? 0 : 1);

    formProvider.updateForm(formId, formBindingData.createFormBindingData(formData)).then(() => {
      hilog.info(DOMAIN_NUMBER, TAG, 'FormAbility updateForm success.');
      console.info('FormAbility updateForm success')
    }).catch((error: Error) => {
      hilog.error(DOMAIN_NUMBER, TAG, `Operation updateForm failed. Cause: ${JSON.stringify(error)}`);
    });
  }

  onRemoveForm(formId: string) {
    UnifiedPreferences.init(this.context);
    UnifiedPreferences.deleteSync('CardType_id' + formId);
    // Called to notify the form provider that a specified form has been destroyed.
  }

  onAcquireFormState(want: Want) {
    // Called to return a {@link FormState} object.
    return formInfo.FormState.READY;
  }
}