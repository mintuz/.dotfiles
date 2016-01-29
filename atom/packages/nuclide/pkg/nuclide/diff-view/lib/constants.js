var _HgStatusToFileChangeStatus, _FileChangeStatusToPrefix;

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

/*
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the LICENSE file in
 * the root directory of this source tree.
 */

var HgStatusCodeNumber = require('../../hg-repository-base').hgConstants.StatusCodeNumber;

var FileChangeStatus = {
  ADDED: 1,
  MODIFIED: 2,
  MISSING: 3,
  REMOVED: 4,
  UNTRACKED: 5
};

var HgStatusToFileChangeStatus = (_HgStatusToFileChangeStatus = {}, _defineProperty(_HgStatusToFileChangeStatus, HgStatusCodeNumber.ADDED, FileChangeStatus.ADDED), _defineProperty(_HgStatusToFileChangeStatus, HgStatusCodeNumber.MODIFIED, FileChangeStatus.MODIFIED), _defineProperty(_HgStatusToFileChangeStatus, HgStatusCodeNumber.MISSING, FileChangeStatus.MISSING), _defineProperty(_HgStatusToFileChangeStatus, HgStatusCodeNumber.REMOVED, FileChangeStatus.REMOVED), _defineProperty(_HgStatusToFileChangeStatus, HgStatusCodeNumber.UNTRACKED, FileChangeStatus.UNTRACKED), _HgStatusToFileChangeStatus);

var FileChangeStatusToPrefix = (_FileChangeStatusToPrefix = {}, _defineProperty(_FileChangeStatusToPrefix, FileChangeStatus.ADDED, '[A] '), _defineProperty(_FileChangeStatusToPrefix, FileChangeStatus.MODIFIED, '[M] '), _defineProperty(_FileChangeStatusToPrefix, FileChangeStatus.MISSING, '[!] '), _defineProperty(_FileChangeStatusToPrefix, FileChangeStatus.REMOVED, '[D] '), _defineProperty(_FileChangeStatusToPrefix, FileChangeStatus.UNTRACKED, '[?] '), _FileChangeStatusToPrefix);

module.exports = {
  FileChangeStatus: FileChangeStatus,
  HgStatusToFileChangeStatus: HgStatusToFileChangeStatus,
  FileChangeStatusToPrefix: FileChangeStatusToPrefix,
  HgStatusCodeNumber: HgStatusCodeNumber
};
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbImNvbnN0YW50cy5qcyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiOzs7Ozs7Ozs7Ozs7SUFXeUIsa0JBQWtCLEdBQUksT0FBTyxDQUFDLDBCQUEwQixDQUFDLENBQUMsV0FBVyxDQUF2RixnQkFBZ0I7O0FBS3ZCLElBQU0sZ0JBQXdELEdBQUc7QUFDL0QsT0FBSyxFQUFFLENBQUM7QUFDUixVQUFRLEVBQUUsQ0FBQztBQUNYLFNBQU8sRUFBRSxDQUFDO0FBQ1YsU0FBTyxFQUFFLENBQUM7QUFDVixXQUFTLEVBQUUsQ0FBQztDQUNiLENBQUM7O0FBRUYsSUFBTSwwQkFBa0YsbUZBQ3JGLGtCQUFrQixDQUFDLEtBQUssRUFBRyxnQkFBZ0IsQ0FBQyxLQUFLLGdEQUNqRCxrQkFBa0IsQ0FBQyxRQUFRLEVBQUcsZ0JBQWdCLENBQUMsUUFBUSxnREFDdkQsa0JBQWtCLENBQUMsT0FBTyxFQUFHLGdCQUFnQixDQUFDLE9BQU8sZ0RBQ3JELGtCQUFrQixDQUFDLE9BQU8sRUFBRyxnQkFBZ0IsQ0FBQyxPQUFPLGdEQUNyRCxrQkFBa0IsQ0FBQyxTQUFTLEVBQUcsZ0JBQWdCLENBQUMsU0FBUywrQkFDM0QsQ0FBQzs7QUFFRixJQUFNLHdCQUFnRSwrRUFDbkUsZ0JBQWdCLENBQUMsS0FBSyxFQUFHLE1BQU0sOENBQy9CLGdCQUFnQixDQUFDLFFBQVEsRUFBRyxNQUFNLDhDQUNsQyxnQkFBZ0IsQ0FBQyxPQUFPLEVBQUcsTUFBTSw4Q0FDakMsZ0JBQWdCLENBQUMsT0FBTyxFQUFHLE1BQU0sOENBQ2pDLGdCQUFnQixDQUFDLFNBQVMsRUFBRyxNQUFNLDZCQUNyQyxDQUFDOztBQUVGLE1BQU0sQ0FBQyxPQUFPLEdBQUc7QUFDZixrQkFBZ0IsRUFBaEIsZ0JBQWdCO0FBQ2hCLDRCQUEwQixFQUExQiwwQkFBMEI7QUFDMUIsMEJBQXdCLEVBQXhCLHdCQUF3QjtBQUN4QixvQkFBa0IsRUFBbEIsa0JBQWtCO0NBQ25CLENBQUMiLCJmaWxlIjoiY29uc3RhbnRzLmpzIiwic291cmNlc0NvbnRlbnQiOlsiJ3VzZSBiYWJlbCc7XG4vKiBAZmxvdyAqL1xuXG4vKlxuICogQ29weXJpZ2h0IChjKSAyMDE1LXByZXNlbnQsIEZhY2Vib29rLCBJbmMuXG4gKiBBbGwgcmlnaHRzIHJlc2VydmVkLlxuICpcbiAqIFRoaXMgc291cmNlIGNvZGUgaXMgbGljZW5zZWQgdW5kZXIgdGhlIGxpY2Vuc2UgZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBpblxuICogdGhlIHJvb3QgZGlyZWN0b3J5IG9mIHRoaXMgc291cmNlIHRyZWUuXG4gKi9cblxuY29uc3Qge1N0YXR1c0NvZGVOdW1iZXI6IEhnU3RhdHVzQ29kZU51bWJlcn0gPSByZXF1aXJlKCcuLi8uLi9oZy1yZXBvc2l0b3J5LWJhc2UnKS5oZ0NvbnN0YW50cztcblxuaW1wb3J0IHR5cGUge1N0YXR1c0NvZGVOdW1iZXJWYWx1ZX0gZnJvbSAnLi4vLi4vaGctcmVwb3NpdG9yeS1iYXNlL2xpYi9oZy1jb25zdGFudHMnO1xuaW1wb3J0IHR5cGUge0ZpbGVDaGFuZ2VTdGF0dXNWYWx1ZX0gZnJvbSAnLi90eXBlcyc7XG5cbmNvbnN0IEZpbGVDaGFuZ2VTdGF0dXM6IHtba2V5OiBzdHJpbmddOiBGaWxlQ2hhbmdlU3RhdHVzVmFsdWV9ID0ge1xuICBBRERFRDogMSxcbiAgTU9ESUZJRUQ6IDIsXG4gIE1JU1NJTkc6IDMsXG4gIFJFTU9WRUQ6IDQsXG4gIFVOVFJBQ0tFRDogNSxcbn07XG5cbmNvbnN0IEhnU3RhdHVzVG9GaWxlQ2hhbmdlU3RhdHVzIDoge1trZXk6IFN0YXR1c0NvZGVOdW1iZXJWYWx1ZV06IEZpbGVDaGFuZ2VTdGF0dXNWYWx1ZX0gPSB7XG4gIFtIZ1N0YXR1c0NvZGVOdW1iZXIuQURERURdOiBGaWxlQ2hhbmdlU3RhdHVzLkFEREVELFxuICBbSGdTdGF0dXNDb2RlTnVtYmVyLk1PRElGSUVEXTogRmlsZUNoYW5nZVN0YXR1cy5NT0RJRklFRCxcbiAgW0hnU3RhdHVzQ29kZU51bWJlci5NSVNTSU5HXTogRmlsZUNoYW5nZVN0YXR1cy5NSVNTSU5HLFxuICBbSGdTdGF0dXNDb2RlTnVtYmVyLlJFTU9WRURdOiBGaWxlQ2hhbmdlU3RhdHVzLlJFTU9WRUQsXG4gIFtIZ1N0YXR1c0NvZGVOdW1iZXIuVU5UUkFDS0VEXTogRmlsZUNoYW5nZVN0YXR1cy5VTlRSQUNLRUQsXG59O1xuXG5jb25zdCBGaWxlQ2hhbmdlU3RhdHVzVG9QcmVmaXg6IHtba2V5OiBGaWxlQ2hhbmdlU3RhdHVzVmFsdWVdOiBzdHJpbmd9ID0ge1xuICBbRmlsZUNoYW5nZVN0YXR1cy5BRERFRF06ICdbQV0gJyxcbiAgW0ZpbGVDaGFuZ2VTdGF0dXMuTU9ESUZJRURdOiAnW01dICcsXG4gIFtGaWxlQ2hhbmdlU3RhdHVzLk1JU1NJTkddOiAnWyFdICcsXG4gIFtGaWxlQ2hhbmdlU3RhdHVzLlJFTU9WRURdOiAnW0RdICcsXG4gIFtGaWxlQ2hhbmdlU3RhdHVzLlVOVFJBQ0tFRF06ICdbP10gJyxcbn07XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICBGaWxlQ2hhbmdlU3RhdHVzLFxuICBIZ1N0YXR1c1RvRmlsZUNoYW5nZVN0YXR1cyxcbiAgRmlsZUNoYW5nZVN0YXR1c1RvUHJlZml4LFxuICBIZ1N0YXR1c0NvZGVOdW1iZXIsXG59O1xuIl19