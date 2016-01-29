var _createClass = (function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ('value' in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; })();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError('Cannot call a class as a function'); } }

/*
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the LICENSE file in
 * the root directory of this source tree.
 */

/**
 * Status codes returned in the "status" field of the testing utility's JSON response.
 */
var Ansi = require('./Ansi');

var Status = {
  PASSED: 1,
  FAILED: 2,
  SKIPPED: 3,
  FATAL: 4,
  TIMEOUT: 5
};

var StatusSymbol = {};
StatusSymbol[Status.PASSED] = Ansi.GREEN + '✓' + Ansi.RESET;
StatusSymbol[Status.FAILED] = Ansi.RED + '✗' + Ansi.RESET;
StatusSymbol[Status.SKIPPED] = Ansi.YELLOW + '?' + Ansi.RESET;
StatusSymbol[Status.FATAL] = Ansi.RED + '✘' + Ansi.RESET;
StatusSymbol[Status.TIMEOUT] = Ansi.BLUE + '✉' + Ansi.RESET;

var StatusMessage = {};
StatusMessage[Status.PASSED] = Ansi.GREEN + '(PASS)' + Ansi.RESET;
StatusMessage[Status.FAILED] = Ansi.RED + '(FAIL)' + Ansi.RESET;
StatusMessage[Status.SKIPPED] = Ansi.YELLOW + '(SKIP)' + Ansi.RESET;
StatusMessage[Status.FATAL] = Ansi.RED + '(FATAL)' + Ansi.RESET;
StatusMessage[Status.TIMEOUT] = Ansi.BLUE + '(TIMEOUT)' + Ansi.RESET;

var TestRunModel = (function () {
  _createClass(TestRunModel, null, [{
    key: 'Status',
    value: Status,
    enumerable: true
  }]);

  function TestRunModel(label, dispose) {
    _classCallCheck(this, TestRunModel);

    this.label = label;
    this.dispose = dispose;
  }

  _createClass(TestRunModel, [{
    key: 'getDuration',
    value: function getDuration() {
      if (this.startTime && this.endTime) {
        return this.endTime - this.startTime;
      }
    }
  }, {
    key: 'start',
    value: function start() {
      this.startTime = Date.now();
    }
  }, {
    key: 'stop',
    value: function stop() {
      this.endTime = Date.now();
    }

    /**
     * @return A summary of the test run including its name, its duration, and whether it passed,
     * failed, skipped, etc.
     */
  }], [{
    key: 'formatStatusMessage',
    value: function formatStatusMessage(name, duration, status) {
      var durationStr = duration.toFixed(3);
      return '      ' + StatusSymbol[status] + ' ' + name + ' ' + durationStr + 's ' + StatusMessage[status];
    }
  }]);

  return TestRunModel;
})();

module.exports = TestRunModel;
//# sourceMappingURL=data:application/json;base64,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QUFDLE1BQU0sQ0FBQyxDQUFHO0tBQ3pGOzs7U0FuQ0csWUFBWTs7O0FBc0NsQixNQUFNLENBQUMsT0FBTyxHQUFHLFlBQVksQ0FBQyIsImZpbGUiOiJUZXN0UnVuTW9kZWwuanMiLCJzb3VyY2VzQ29udGVudCI6WyIndXNlIGJhYmVsJztcbi8qIEBmbG93ICovXG5cbi8qXG4gKiBDb3B5cmlnaHQgKGMpIDIwMTUtcHJlc2VudCwgRmFjZWJvb2ssIEluYy5cbiAqIEFsbCByaWdodHMgcmVzZXJ2ZWQuXG4gKlxuICogVGhpcyBzb3VyY2UgY29kZSBpcyBsaWNlbnNlZCB1bmRlciB0aGUgbGljZW5zZSBmb3VuZCBpbiB0aGUgTElDRU5TRSBmaWxlIGluXG4gKiB0aGUgcm9vdCBkaXJlY3Rvcnkgb2YgdGhpcyBzb3VyY2UgdHJlZS5cbiAqL1xuXG5jb25zdCBBbnNpID0gcmVxdWlyZSgnLi9BbnNpJyk7XG5cbmltcG9ydCB0eXBlIHtUZXN0UnVuU3RhdHVzfSBmcm9tICcuLi8uLi90ZXN0LXJ1bm5lci1pbnRlcmZhY2VzJztcblxuLyoqXG4gKiBTdGF0dXMgY29kZXMgcmV0dXJuZWQgaW4gdGhlIFwic3RhdHVzXCIgZmllbGQgb2YgdGhlIHRlc3RpbmcgdXRpbGl0eSdzIEpTT04gcmVzcG9uc2UuXG4gKi9cbmNvbnN0IFN0YXR1czoge1trZXk6IHN0cmluZ106IFRlc3RSdW5TdGF0dXN9ID0ge1xuICBQQVNTRUQ6IDEsXG4gIEZBSUxFRDogMixcbiAgU0tJUFBFRDogMyxcbiAgRkFUQUw6IDQsXG4gIFRJTUVPVVQ6IDUsXG59O1xuXG5jb25zdCBTdGF0dXNTeW1ib2w6IHtba2V5OiBUZXN0UnVuU3RhdHVzXTogc3RyaW5nfSA9IHt9O1xuU3RhdHVzU3ltYm9sW1N0YXR1cy5QQVNTRURdID0gYCR7QW5zaS5HUkVFTn3inJMke0Fuc2kuUkVTRVR9YDtcblN0YXR1c1N5bWJvbFtTdGF0dXMuRkFJTEVEXSA9IGAke0Fuc2kuUkVEfeKclyR7QW5zaS5SRVNFVH1gO1xuU3RhdHVzU3ltYm9sW1N0YXR1cy5TS0lQUEVEXSA9IGAke0Fuc2kuWUVMTE9XfT8ke0Fuc2kuUkVTRVR9YDtcblN0YXR1c1N5bWJvbFtTdGF0dXMuRkFUQUxdID0gYCR7QW5zaS5SRUR94pyYJHtBbnNpLlJFU0VUfWA7XG5TdGF0dXNTeW1ib2xbU3RhdHVzLlRJTUVPVVRdID0gYCR7QW5zaS5CTFVFfeKciSR7QW5zaS5SRVNFVH1gO1xuXG5jb25zdCBTdGF0dXNNZXNzYWdlOiB7W2tleTogVGVzdFJ1blN0YXR1c106IHN0cmluZ30gPSB7fTtcblN0YXR1c01lc3NhZ2VbU3RhdHVzLlBBU1NFRF0gPSBgJHtBbnNpLkdSRUVOfShQQVNTKSR7QW5zaS5SRVNFVH1gO1xuU3RhdHVzTWVzc2FnZVtTdGF0dXMuRkFJTEVEXSA9IGAke0Fuc2kuUkVEfShGQUlMKSR7QW5zaS5SRVNFVH1gO1xuU3RhdHVzTWVzc2FnZVtTdGF0dXMuU0tJUFBFRF0gPSBgJHtBbnNpLllFTExPV30oU0tJUCkke0Fuc2kuUkVTRVR9YDtcblN0YXR1c01lc3NhZ2VbU3RhdHVzLkZBVEFMXSA9IGAke0Fuc2kuUkVEfShGQVRBTCkke0Fuc2kuUkVTRVR9YDtcblN0YXR1c01lc3NhZ2VbU3RhdHVzLlRJTUVPVVRdID0gYCR7QW5zaS5CTFVFfShUSU1FT1VUKSR7QW5zaS5SRVNFVH1gO1xuXG5jbGFzcyBUZXN0UnVuTW9kZWwge1xuXG4gIHN0YXRpYyBTdGF0dXM6IHtba2V5OiBzdHJpbmddOiBUZXN0UnVuU3RhdHVzfSA9IFN0YXR1cztcblxuICBzdGFydFRpbWU6ID9udW1iZXI7XG4gIGVuZFRpbWU6ID9udW1iZXI7XG4gIGxhYmVsOiBzdHJpbmc7XG4gIGRpc3Bvc2U6ID8oKSA9PiB2b2lkO1xuXG4gIGNvbnN0cnVjdG9yKGxhYmVsOiBzdHJpbmcsIGRpc3Bvc2U6ICgpID0+IHZvaWQpIHtcbiAgICB0aGlzLmxhYmVsID0gbGFiZWw7XG4gICAgdGhpcy5kaXNwb3NlID0gZGlzcG9zZTtcbiAgfVxuXG4gIGdldER1cmF0aW9uKCk6ID9udW1iZXIge1xuICAgIGlmICh0aGlzLnN0YXJ0VGltZSAmJiB0aGlzLmVuZFRpbWUpIHtcbiAgICAgIHJldHVybiB0aGlzLmVuZFRpbWUgLSB0aGlzLnN0YXJ0VGltZTtcbiAgICB9XG4gIH1cblxuICBzdGFydCgpOiB2b2lkIHtcbiAgICB0aGlzLnN0YXJ0VGltZSA9IERhdGUubm93KCk7XG4gIH1cblxuICBzdG9wKCk6IHZvaWQge1xuICAgIHRoaXMuZW5kVGltZSA9IERhdGUubm93KCk7XG4gIH1cblxuICAvKipcbiAgICogQHJldHVybiBBIHN1bW1hcnkgb2YgdGhlIHRlc3QgcnVuIGluY2x1ZGluZyBpdHMgbmFtZSwgaXRzIGR1cmF0aW9uLCBhbmQgd2hldGhlciBpdCBwYXNzZWQsXG4gICAqIGZhaWxlZCwgc2tpcHBlZCwgZXRjLlxuICAgKi9cbiAgc3RhdGljIGZvcm1hdFN0YXR1c01lc3NhZ2UobmFtZTogc3RyaW5nLCBkdXJhdGlvbjogbnVtYmVyLCBzdGF0dXM6IFRlc3RSdW5TdGF0dXMpOiBzdHJpbmcge1xuICAgIGNvbnN0IGR1cmF0aW9uU3RyID0gZHVyYXRpb24udG9GaXhlZCgzKTtcbiAgICByZXR1cm4gYCAgICAgICR7U3RhdHVzU3ltYm9sW3N0YXR1c119ICR7bmFtZX0gJHtkdXJhdGlvblN0cn1zICR7U3RhdHVzTWVzc2FnZVtzdGF0dXNdfWA7XG4gIH1cbn1cblxubW9kdWxlLmV4cG9ydHMgPSBUZXN0UnVuTW9kZWw7XG4iXX0=