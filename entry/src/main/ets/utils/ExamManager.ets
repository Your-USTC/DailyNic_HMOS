import * as ExamStorage from './ExamStorage';

export function areExamAttributesEqual(a: ExamStorage.examAttribute, b: ExamStorage.examAttribute): boolean {
  // 基本类型直接比较
  if (a.id !== b.id) return false;
  if (a.type !== b.type) return false;
  if (a.name !== b.name) return false;
  if (a.date !== b.date) return false;
  if (a.classroom !== b.classroom) return false;
  if (a.building !== b.building) return false;
  if (a.campus !== b.campus) return false;
  if (a.info !== b.info) return false;
  if (a.importance !== b.importance) return false;
  // 所有字段都相同
  return true;
}

class examManager {
  allExamInfo: ExamStorage.examAttribute[] = [];

  readStoredExam() {
    this.allExamInfo = ExamStorage.getExams();
  }

  storeExam(data: ExamStorage.examAttribute[]) {
    for (let i = 0; i < data.length; i++) {
      data[i].beginTimeStamp = new Date(data[i].date.slice(0, 16)).getTime();
      data[i].endTimeStamp = new Date(data[i].date.slice(0, 11) + data[i].date.slice(17, 22)).getTime();
      if (data[i].importance == undefined)
        data[i].importance = 5;
    }
    data.sort((a, b) => {
      if (a.importance !== b.importance) {
        return b.importance - a.importance;
      }
      return a.beginTimeStamp - b.beginTimeStamp;
    });
    ExamStorage.setExams(data);
  }

  addExam(newExam: ExamStorage.examAttribute) {
    newExam.beginTimeStamp = new Date(newExam.date.slice(0, 16)).getTime();
    newExam.endTimeStamp = new Date(newExam.date.slice(0, 11) + newExam.date.slice(17, 22)).getTime();
    this.allExamInfo.push(newExam);
    this.allExamInfo.sort((a, b) => {
      if (a.importance !== b.importance) {
        return b.importance - a.importance;
      }
      return a.beginTimeStamp - b.beginTimeStamp;
    });
    ExamStorage.setExams(this.allExamInfo);
  }

  deleteExam(deletedExam: ExamStorage.examAttribute) {
    for (let i = this.allExamInfo.length - 1; i >= 0; i--)
      if (areExamAttributesEqual(deletedExam, this.allExamInfo[i])) {
        this.allExamInfo.splice(i, 1);
        break;
      }
    this.storeExam(this.allExamInfo);
  }
}

export default new examManager();