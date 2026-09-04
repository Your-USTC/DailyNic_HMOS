import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
const tokenID = bundleManager.getBundleInfoForSelfSync(0x00000001/*GET_BUNDLE_INFO_WITH_APPLICATION*/).appInfo.accessTokenId;

export async function checkPermission(permissionList: Permissions[]): Promise<boolean> {
  const promiseList = permissionList.map(async (permission) => {
    const grantStatus = await atManager.checkAccessToken(tokenID, permission);
    return grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  });
  const checkResults = await Promise.all(promiseList);
  return checkResults.every(result => result === true);
}

export enum PermissionRequestState {
  GRANTED, // 已授权
  DENIED, // 用户在授权弹窗中拒绝
  BLOCKED // 此前勾选了"禁止后不再询问"，普通授权弹窗不再弹出
}

export async function regainPermission(context: common.Context, permissionList: Permissions[]): Promise<PermissionRequestState> {
  if (await checkPermission(permissionList))
    return PermissionRequestState.GRANTED;
  try {
    const data = await atManager.requestPermissionsFromUser(context, permissionList);
    if (data.authResults.every(result => result === 0/*PERMISSION_GRANTED*/))
      return PermissionRequestState.GRANTED;
    // 用户勾选"禁止后不再询问"时 requestPermissionsFromUser 不再弹窗（dialogShownResults 为 false）
    if (data.dialogShownResults !== undefined && data.dialogShownResults.some(shown => !shown))
      return PermissionRequestState.BLOCKED;
    return PermissionRequestState.DENIED;
  } catch (err) {
    const e = err as BusinessError;
    console.error(`requestPermissionsFromUser fail, code: ${e.code}, message: ${e.message}`);
    return PermissionRequestState.DENIED;
  }
}

export async function openPermissionSetting(context: common.Context, permissionList: Permissions[]): Promise<boolean> {
  try {
    const statuses = await atManager.requestPermissionOnSetting(context, permissionList);
    return statuses.every(status => status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED);
  } catch (err) {
    const e = err as BusinessError;
    console.error(`requestPermissionOnSetting fail, code: ${e.code}, message: ${e.message}`);
    return false;
  }
}