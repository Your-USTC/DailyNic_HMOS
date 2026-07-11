import {
  AnswerFileName,
  answerSession,
  answerRecord,
  sessionSummary,
  answerMark,
  singleQuestion,
  PracticeMode
} from "./constants";
import { fileIo } from "@kit.CoreFileKit";
import { BasicDir } from "./constants";
import { getQuestions, updateQuestions } from "./TestManager";

function getSessionPath(uuid: string): string {
  return BasicDir + uuid + '/' + AnswerFileName;
}

export function initSession(uuid: string, mode: PracticeMode): answerSession {
  const questions = getQuestions(uuid);
  const session: answerSession = {
    lastAnswerTime: Date.now(),
    mode: mode,
    starred: false,
    marks: questions.map(() => ({ starred: false, ignore: false } satisfies answerMark)),
    questionNO: undefined,
    answers: [],
    currentIndex: 0
  };
  if (mode === 'incorrect') {
    session.questionNO = [];
  }
  saveSession(uuid, session);
  return session;
}

export function loadSession(uuid: string): answerSession | null {
  const path = getSessionPath(uuid);
  try {
    const text = fileIo.readTextSync(path);
    return JSON.parse(text) as answerSession;
  } catch (e) {
    return null;
  }
}

export function saveSession(uuid: string, session: answerSession): void {
  const path = getSessionPath(uuid);
  session.lastAnswerTime = Date.now();
  const file = fileIo.openSync(path, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
  fileIo.writeSync(file.fd, JSON.stringify(session));
  fileIo.closeSync(file);
}

export function checkAnswer(question: singleQuestion, userAnswer: string): boolean {
  if (!userAnswer) {
    return false;
  }
  const trimmed = userAnswer.trim();
  if (question.type === 'single') {
    return trimmed.toUpperCase() === question.answer.trim().toUpperCase();
  }
  if (question.type === 'blank') {
    return trimmed === question.answer.trim();
  }
  if (question.type === 'multiple') {
    const userParts = trimmed.split('').filter(c => c.match(/[A-Za-z]/)).map(c => c.toUpperCase()).sort();
    const correctParts = question.answer.split('').filter(c => c.match(/[A-Za-z]/)).map(c => c.toUpperCase()).sort();
    if (userParts.length !== correctParts.length) {
      return false;
    }
    return userParts.every((v, i) => v === correctParts[i]);
  }
  return false;
}

export function recordAnswer(uuid: string, questionIndex: number, userAnswer: string): answerRecord | null {
  const session = loadSession(uuid);
  if (!session) {
    return null;
  }
  const questions = getQuestions(uuid);
  if (questionIndex < 0 || questionIndex >= questions.length) {
    return null;
  }
  const isCorrect = checkAnswer(questions[questionIndex], userAnswer);
  const record: answerRecord = {
    questionIndex: questionIndex,
    userAnswer: userAnswer,
    isCorrect: isCorrect,
    timestamp: Date.now()
  };
  const existingIdx = session.answers.findIndex(a => a.questionIndex === questionIndex);
  if (existingIdx >= 0) {
    session.answers[existingIdx] = record;
  } else {
    session.answers.push(record);
  }
  if (session.mode === 'incorrect') {
    if (isCorrect && session.questionNO) {
      const qIdx = session.questionNO.indexOf(questionIndex);
      if (qIdx >= 0) {
        session.questionNO.splice(qIdx, 1);
      }
    } else if (!isCorrect && session.questionNO) {
      if (session.questionNO.indexOf(questionIndex) < 0) {
        session.questionNO.push(questionIndex);
      }
    }
  }
  saveSession(uuid, session);
  return record;
}

export function getSessionSummary(uuid: string): sessionSummary | null {
  const questions = getQuestions(uuid);
  const session = loadSession(uuid);
  if (!session) {
    return null;
  }
  const correct = session.answers.filter(a => a.isCorrect).length;
  const wrong = session.answers.filter(a => !a.isCorrect).length;
  return {
    total: questions.length,
    answered: session.answers.length,
    correct: correct,
    wrong: wrong
  };
}

export function getAnswerRecord(uuid: string, questionIndex: number): answerRecord | null {
  const session = loadSession(uuid);
  if (!session) {
    return null;
  }
  return session.answers.find(a => a.questionIndex === questionIndex) || null;
}

export function getQuestionOrder(uuid: string): number[] {
  const session = loadSession(uuid);
  const questions = getQuestions(uuid);
  if (!session) {
    return questions.map((_, i) => i);
  }
  let indices: number[];
  if (session.mode === 'incorrect' && session.questionNO !== undefined) {
    indices = session.questionNO.length > 0 ? [...session.questionNO] : questions.map((_, i) => i);
  } else {
    indices = questions.map((_, i) => i);
  }
  if (session.starred) {
    indices = indices.filter(i => session.marks[i] && session.marks[i].starred);
  }
  indices = indices.filter(i =>
    !(session.marks[i] && session.marks[i].ignore) && i < questions.length
  );
  if (session.mode === 'random') {
    for (let i = indices.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      const tmp = indices[i];
      indices[i] = indices[j];
      indices[j] = tmp;
    }
  }
  return indices;
}

export function getCurrentQuestionIndex(uuid: string): number {
  const session = loadSession(uuid);
  if (!session) {
    return 0;
  }
  return session.currentIndex;
}

export function setCurrentQuestionIndex(uuid: string, index: number): void {
  const session = loadSession(uuid);
  if (session) {
    session.currentIndex = index;
    saveSession(uuid, session);
  }
}

export function updateQuestionMark(uuid: string, questionIndex: number, mark: answerMark): void {
  const session = loadSession(uuid);
  if (!session) {
    return;
  }
  if (questionIndex < 0 || questionIndex >= session.marks.length) {
    return;
  }
  session.marks[questionIndex] = mark;
  saveSession(uuid, session);
}

export function syncMarksToQuestions(uuid: string): void {
  const session = loadSession(uuid);
  if (!session) {
    return;
  }
  const questions = getQuestions(uuid);
  for (let i = 0; i < questions.length && i < session.marks.length; i++) {
    questions[i].starred = session.marks[i].starred;
    questions[i].ignore = session.marks[i].ignore;
  }
  updateQuestions(uuid, questions);
}

export function hasActiveSession(uuid: string): boolean {
  const path = getSessionPath(uuid);
  return fileIo.accessSync(path);
}

export function deleteSession(uuid: string): void {
  const path = getSessionPath(uuid);
  if (fileIo.accessSync(path)) {
    fileIo.rmdirSync(path);
  }
}