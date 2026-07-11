import { readDataFromCsv, getObjectFromCsv } from './DataTransformer';
import { common } from '@kit.AbilityKit';
import { createTest } from './TestManager';
import { singleQuestion } from './constants';

export async function importNewTest(title: string, context: UIContext) {
  const data: singleQuestion[] = getObjectFromCsv(await readDataFromCsv(context.getHostContext() as common.UIAbilityContext));
  if (data.length === 0) {
    return;
  }
  createTest(data, title);
}