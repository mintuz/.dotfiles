

/*
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the LICENSE file in
 * the root directory of this source tree.
 */

var flatten = require('../../utils/flatten');
var markers = require('../../constants/markers');

function printUnionTypeAnnotation(print, node) {
  return flatten([markers.openScope, markers.scopeIndent, node.types.map(function (t, i, arr) {
    return [i === 0 ? markers.scopeBreak : markers.scopeSpaceBreak, print(t), i < arr.length - 1 ? [markers.space, '|'] : markers.empty];
  }), markers.scopeDedent, markers.closeScope]);
}

module.exports = printUnionTypeAnnotation;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbInByaW50VW5pb25UeXBlQW5ub3RhdGlvbi5qcyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiOzs7Ozs7Ozs7O0FBY0EsSUFBTSxPQUFPLEdBQUcsT0FBTyxDQUFDLHFCQUFxQixDQUFDLENBQUM7QUFDL0MsSUFBTSxPQUFPLEdBQUcsT0FBTyxDQUFDLHlCQUF5QixDQUFDLENBQUM7O0FBRW5ELFNBQVMsd0JBQXdCLENBQy9CLEtBQVksRUFDWixJQUF5QixFQUNsQjtBQUNQLFNBQU8sT0FBTyxDQUFDLENBQ2IsT0FBTyxDQUFDLFNBQVMsRUFDakIsT0FBTyxDQUFDLFdBQVcsRUFDbkIsSUFBSSxDQUFDLEtBQUssQ0FBQyxHQUFHLENBQUMsVUFBQyxDQUFDLEVBQUUsQ0FBQyxFQUFFLEdBQUc7V0FBSyxDQUM1QixDQUFDLEtBQUssQ0FBQyxHQUFHLE9BQU8sQ0FBQyxVQUFVLEdBQUcsT0FBTyxDQUFDLGVBQWUsRUFDdEQsS0FBSyxDQUFDLENBQUMsQ0FBQyxFQUNSLENBQUMsR0FBRyxHQUFHLENBQUMsTUFBTSxHQUFHLENBQUMsR0FBRyxDQUFDLE9BQU8sQ0FBQyxLQUFLLEVBQUUsR0FBRyxDQUFDLEdBQUcsT0FBTyxDQUFDLEtBQUssQ0FDMUQ7R0FBQSxDQUFDLEVBQ0YsT0FBTyxDQUFDLFdBQVcsRUFDbkIsT0FBTyxDQUFDLFVBQVUsQ0FDbkIsQ0FBQyxDQUFDO0NBQ0o7O0FBRUQsTUFBTSxDQUFDLE9BQU8sR0FBRyx3QkFBd0IsQ0FBQyIsImZpbGUiOiJwcmludFVuaW9uVHlwZUFubm90YXRpb24uanMiLCJzb3VyY2VzQ29udGVudCI6WyIndXNlIGJhYmVsJztcbi8qIEBmbG93ICovXG5cbi8qXG4gKiBDb3B5cmlnaHQgKGMpIDIwMTUtcHJlc2VudCwgRmFjZWJvb2ssIEluYy5cbiAqIEFsbCByaWdodHMgcmVzZXJ2ZWQuXG4gKlxuICogVGhpcyBzb3VyY2UgY29kZSBpcyBsaWNlbnNlZCB1bmRlciB0aGUgbGljZW5zZSBmb3VuZCBpbiB0aGUgTElDRU5TRSBmaWxlIGluXG4gKiB0aGUgcm9vdCBkaXJlY3Rvcnkgb2YgdGhpcyBzb3VyY2UgdHJlZS5cbiAqL1xuXG5pbXBvcnQgdHlwZSB7TGluZXMsIFByaW50fSBmcm9tICcuLi8uLi90eXBlcy9jb21tb24nO1xuaW1wb3J0IHR5cGUge1VuaW9uVHlwZUFubm90YXRpb259IGZyb20gJ2FzdC10eXBlcy1mbG93JztcblxuY29uc3QgZmxhdHRlbiA9IHJlcXVpcmUoJy4uLy4uL3V0aWxzL2ZsYXR0ZW4nKTtcbmNvbnN0IG1hcmtlcnMgPSByZXF1aXJlKCcuLi8uLi9jb25zdGFudHMvbWFya2VycycpO1xuXG5mdW5jdGlvbiBwcmludFVuaW9uVHlwZUFubm90YXRpb24oXG4gIHByaW50OiBQcmludCxcbiAgbm9kZTogVW5pb25UeXBlQW5ub3RhdGlvbixcbik6IExpbmVzIHtcbiAgcmV0dXJuIGZsYXR0ZW4oW1xuICAgIG1hcmtlcnMub3BlblNjb3BlLFxuICAgIG1hcmtlcnMuc2NvcGVJbmRlbnQsXG4gICAgbm9kZS50eXBlcy5tYXAoKHQsIGksIGFycikgPT4gW1xuICAgICAgaSA9PT0gMCA/IG1hcmtlcnMuc2NvcGVCcmVhayA6IG1hcmtlcnMuc2NvcGVTcGFjZUJyZWFrLFxuICAgICAgcHJpbnQodCksXG4gICAgICBpIDwgYXJyLmxlbmd0aCAtIDEgPyBbbWFya2Vycy5zcGFjZSwgJ3wnXSA6IG1hcmtlcnMuZW1wdHksXG4gICAgXSksXG4gICAgbWFya2Vycy5zY29wZURlZGVudCxcbiAgICBtYXJrZXJzLmNsb3NlU2NvcGUsXG4gIF0pO1xufVxuXG5tb2R1bGUuZXhwb3J0cyA9IHByaW50VW5pb25UeXBlQW5ub3RhdGlvbjtcbiJdfQ==